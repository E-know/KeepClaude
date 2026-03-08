import Foundation

struct GitHubRepository: GitHubRepositoryProtocol {
    private let githubService: any GitHubAPIServicing

    init(githubService: any GitHubAPIServicing = GitHubAPIService()) {
        self.githubService = githubService
    }

    func ensureRepoExists(name: String, token: String) async throws -> GitHubRepo {
        let user: GitHubUser = try await githubService.request(.getUser(token: token))
        do {
            return try await githubService.request(.getRepo(owner: user.login, repo: name, token: token))
        } catch is NetworkError {
            let repo: GitHubRepo = try await githubService.request(
                .createRepo(name: name, isPrivate: false, token: token)
            )
            try await waitForRepoReady(owner: user.login, repo: repo.name, branch: repo.defaultBranch, token: token)
            return repo
        }
    }

    func pushSettings(
        _ settings: ClaudeSettings,
        owner: String, repo: String, branch: String,
        message: String, token: String
    ) async throws {
        let files = settingsToFileMap(settings)
        guard !files.isEmpty else { return }

        // 1. Get current ref
        let ref: GitHubDTO.RefResponse = try await githubService.request(
            .getRef(owner: owner, repo: repo, ref: "heads/\(branch)", token: token)
        )
        let currentCommitSha = ref.object.sha

        // 2. Get current commit to find tree SHA
        let commitDetail: GitHubDTO.CommitDetail = try await githubService.request(
            GitHubEndpoint(
                path: "/repos/\(owner)/\(repo)/git/commits/\(currentCommitSha)",
                method: .get, body: nil, token: token
            )
        )
        let baseTreeSha = commitDetail.tree.sha

        // 3. Create blobs for each file
        var treeEntries: [[String: String]] = []
        for (path, data) in files {
            let isText = !path.hasSuffix(".aiff") && !path.hasSuffix(".wav") && !path.hasSuffix(".mp3")
            let content: String
            let encoding: String

            if isText {
                content = String(data: data, encoding: .utf8) ?? data.base64EncodedString()
                encoding = "utf-8"
            } else {
                content = data.base64EncodedString()
                encoding = "base64"
            }

            let blob: GitHubDTO.BlobResponse = try await githubService.request(
                .createBlob(owner: owner, repo: repo, content: content, encoding: encoding, token: token)
            )
            treeEntries.append([
                "path": path,
                "mode": "100644",
                "type": "blob",
                "sha": blob.sha
            ])
        }

        // 4. Create tree
        let tree: GitHubDTO.TreeResponse = try await githubService.request(
            .createTree(owner: owner, repo: repo, baseTree: baseTreeSha, tree: treeEntries, token: token)
        )

        // 5. Create commit
        let commit: GitHubDTO.CommitResponse = try await githubService.request(
            .createCommit(
                owner: owner, repo: repo,
                message: message, tree: tree.sha,
                parents: [currentCommitSha], token: token
            )
        )

        // 6. Update ref
        let _: GitHubDTO.RefResponse = try await githubService.request(
            .updateRef(owner: owner, repo: repo, ref: "heads/\(branch)", sha: commit.sha, token: token)
        )
    }

    func fetchRemoteSettings(
        owner: String, repo: String, token: String?
    ) async throws -> ClaudeSettings {
        let rootContents: [GitHubDTO.ContentItem] = try await githubService.request(
            .getContents(owner: owner, repo: repo, path: "", token: token)
        )

        var coreSettings: CoreSettings?
        var localSettings: CoreSettings?
        var keybindings: Data?
        var plugins: PluginSettings?
        var skills: [SkillDefinition] = []
        var commands: [CommandDefinition] = []
        var sounds: [SoundFile] = []

        for item in rootContents {
            switch item.name {
            case Constants.SyncTargets.settingsJSON:
                if let data = try await fetchFileContent(owner: owner, repo: repo, path: item.path, token: token) {
                    coreSettings = try? JSONDecoder().decode(CoreSettings.self, from: data)
                }
            case Constants.SyncTargets.settingsLocalJSON:
                if let data = try await fetchFileContent(owner: owner, repo: repo, path: item.path, token: token) {
                    localSettings = try? JSONDecoder().decode(CoreSettings.self, from: data)
                }
            case Constants.SyncTargets.keybindingsJSON:
                keybindings = try await fetchFileContent(owner: owner, repo: repo, path: item.path, token: token)
            case Constants.SyncTargets.pluginsDir:
                plugins = try await fetchPlugins(owner: owner, repo: repo, token: token)
            case Constants.SyncTargets.skillsDir:
                skills = try await fetchSkills(owner: owner, repo: repo, token: token)
            case Constants.SyncTargets.commandsDir:
                commands = try await fetchCommands(owner: owner, repo: repo, token: token)
            case "sounds":
                sounds = try await fetchSounds(owner: owner, repo: repo, token: token)
            default:
                break
            }
        }

        return ClaudeSettings(
            coreSettings: coreSettings,
            localSettings: localSettings,
            keybindings: keybindings,
            plugins: plugins,
            skills: skills,
            commands: commands,
            sounds: sounds
        )
    }

    func compareWithRemote(
        local: ClaudeSettings, owner: String, repo: String, token: String?
    ) async throws -> SettingsDiff {
        let remote = try await fetchRemoteSettings(owner: owner, repo: repo, token: token)
        let localFiles = settingsToFileMap(local)
        let remoteFiles = settingsToFileMap(remote)

        let localDict = Dictionary(localFiles, uniquingKeysWith: { first, _ in first })
        let remoteDict = Dictionary(remoteFiles, uniquingKeysWith: { first, _ in first })

        var diffs: [FileDiff] = []
        let allPaths = Set(localDict.keys).union(remoteDict.keys)

        for path in allPaths.sorted() {
            let localData = localDict[path]
            let remoteData = remoteDict[path]

            let status: DiffStatus
            if localData != nil && remoteData == nil {
                status = .added
            } else if localData == nil && remoteData != nil {
                status = .deleted
            } else if localData != remoteData {
                status = .modified
            } else {
                status = .unchanged
            }

            diffs.append(FileDiff(
                path: path,
                status: status,
                localSize: localData.map { UInt64($0.count) },
                remoteSize: remoteData.map { UInt64($0.count) }
            ))
        }

        return SettingsDiff(diffs: diffs)
    }

    // MARK: - Private Helpers

    private func waitForRepoReady(owner: String, repo: String, branch: String, token: String) async throws {
        for attempt in 1...5 {
            do {
                let _: GitHubDTO.RefResponse = try await githubService.request(
                    .getRef(owner: owner, repo: repo, ref: "heads/\(branch)", token: token)
                )
                return
            } catch is NetworkError {
                if attempt == 5 {
                    throw NetworkError.networkError(
                        "Repository 초기화가 완료되지 않았습니다. 잠시 후 다시 시도해주세요."
                    )
                }
                try await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func fetchFileContent(owner: String, repo: String, path: String, token: String?) async throws -> Data? {
        let item: GitHubDTO.ContentItem = try await githubService.request(
            .getContents(owner: owner, repo: repo, path: path, token: token)
        )
        guard let content = item.content else { return nil }
        let cleaned = content.replacingOccurrences(of: "\n", with: "")
        return Data(base64Encoded: cleaned)
    }

    private func fetchPlugins(owner: String, repo: String, token: String?) async throws -> PluginSettings? {
        guard let installedData = try await fetchFileContent(
            owner: owner, repo: repo, path: "plugins/installed_plugins.json", token: token
        ) else { return nil }

        let installed = try JSONDecoder().decode(InstalledPluginsFile.self, from: installedData)

        guard let marketplacesData = try await fetchFileContent(
            owner: owner, repo: repo, path: "plugins/known_marketplaces.json", token: token
        ) else { return nil }

        let marketplaces = try JSONDecoder().decode([String: KnownMarketplace].self, from: marketplacesData)

        var config: PluginConfig?
        if let data = try? await fetchFileContent(owner: owner, repo: repo, path: "plugins/config.json", token: token) {
            config = try? JSONDecoder().decode(PluginConfig.self, from: data)
        }

        var blocklist: PluginBlocklist?
        if let data = try? await fetchFileContent(owner: owner, repo: repo, path: "plugins/blocklist.json", token: token) {
            blocklist = try? JSONDecoder().decode(PluginBlocklist.self, from: data)
        }

        return PluginSettings(installedPlugins: installed, knownMarketplaces: marketplaces, config: config, blocklist: blocklist)
    }

    private func fetchSkills(owner: String, repo: String, token: String?) async throws -> [SkillDefinition] {
        let contents: [GitHubDTO.ContentItem] = try await githubService.request(
            .getContents(owner: owner, repo: repo, path: "skills", token: token)
        )
        var skills: [SkillDefinition] = []
        for dir in contents where dir.type == "dir" {
            if let data = try? await fetchFileContent(
                owner: owner, repo: repo, path: "\(dir.path)/SKILL.md", token: token
            ) {
                let content = String(data: data, encoding: .utf8) ?? ""
                skills.append(SkillDefinition(name: dir.name, content: content))
            }
        }
        return skills
    }

    private func fetchCommands(owner: String, repo: String, token: String?) async throws -> [CommandDefinition] {
        let contents: [GitHubDTO.ContentItem] = try await githubService.request(
            .getContents(owner: owner, repo: repo, path: "commands", token: token)
        )
        var commands: [CommandDefinition] = []
        for file in contents where file.name.hasSuffix(".md") {
            if let data = try? await fetchFileContent(
                owner: owner, repo: repo, path: file.path, token: token
            ) {
                let content = String(data: data, encoding: .utf8) ?? ""
                let name = String(file.name.dropLast(3))
                commands.append(CommandDefinition(name: name, content: content))
            }
        }
        return commands
    }

    private func fetchSounds(owner: String, repo: String, token: String?) async throws -> [SoundFile] {
        let contents: [GitHubDTO.ContentItem] = try await githubService.request(
            .getContents(owner: owner, repo: repo, path: "sounds", token: token)
        )
        var sounds: [SoundFile] = []
        for file in contents {
            if let data = try? await fetchFileContent(
                owner: owner, repo: repo, path: file.path, token: token
            ) {
                sounds.append(SoundFile(name: file.name, data: data, size: UInt64(data.count)))
            }
        }
        return sounds
    }

    func settingsToFileMap(_ settings: ClaudeSettings) -> [(path: String, data: Data)] {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        var files: [(String, Data)] = []

        // Manifest (no sanitization — generated data, no user paths)
        if let manifestData = try? encoder.encode(buildManifest(for: settings)) {
            files.append((Constants.manifestFileName, manifestData))
        }

        if let core = settings.coreSettings, let data = try? encoder.encode(core) {
            files.append((Constants.SyncTargets.settingsJSON, PathSubstitution.sanitizeData(data)))
        }
        if let local = settings.localSettings, let data = try? encoder.encode(local) {
            files.append((Constants.SyncTargets.settingsLocalJSON, PathSubstitution.sanitizeData(data)))
        }
        if let kb = settings.keybindings {
            files.append((Constants.SyncTargets.keybindingsJSON, PathSubstitution.sanitizeData(kb)))
        }
        if let plugins = settings.plugins {
            if let data = try? encoder.encode(plugins.installedPlugins) {
                files.append(("plugins/installed_plugins.json", PathSubstitution.sanitizeData(data)))
            }
            if let data = try? encoder.encode(plugins.knownMarketplaces) {
                files.append(("plugins/known_marketplaces.json", PathSubstitution.sanitizeData(data)))
            }
            if let config = plugins.config, let data = try? encoder.encode(config) {
                files.append(("plugins/config.json", PathSubstitution.sanitizeData(data)))
            }
            if let blocklist = plugins.blocklist, let data = try? encoder.encode(blocklist) {
                files.append(("plugins/blocklist.json", PathSubstitution.sanitizeData(data)))
            }
        }
        for skill in settings.skills {
            files.append(("skills/\(skill.name)/SKILL.md", PathSubstitution.sanitizeData(Data(skill.content.utf8))))
        }
        for command in settings.commands {
            files.append(("commands/\(command.name).md", PathSubstitution.sanitizeData(Data(command.content.utf8))))
        }
        for sound in settings.sounds {
            files.append(("sounds/\(sound.name)", sound.data))
        }

        return files
    }

    private func buildManifest(for settings: ClaudeSettings) -> Manifest {
        let formatter = ISO8601DateFormatter()
        return Manifest(
            version: Constants.manifestVersion,
            appVersion: Constants.appVersion,
            syncedAt: formatter.string(from: Date()),
            syncedBy: "",
            platform: PlatformInfo(
                os: "macOS",
                osVersion: ProcessInfo.processInfo.operatingSystemVersionString
            ),
            categories: Dictionary(
                uniqueKeysWithValues: SettingsCategory.allCases.map {
                    ($0.rawValue, settings.availableCategories().contains($0))
                }
            ),
            summary: SyncSummary(
                pluginCount: settings.plugins?.installedPlugins.plugins.count ?? 0,
                skillCount: settings.skills.count,
                commandCount: settings.commands.count,
                soundCount: settings.sounds.count
            )
        )
    }
}
