import Foundation

struct ClaudeSettingsRepository: ClaudeSettingsRepositoryProtocol, @unchecked Sendable {
    private let fileSystemService: any FileSystemServicing
    private let claudeDir: URL

    init(
        fileSystemService: any FileSystemServicing = FileSystemService(),
        claudeDirectory: URL = Constants.claudeDirectoryURL
    ) {
        self.fileSystemService = fileSystemService
        self.claudeDir = claudeDirectory
    }

    func scan() async throws -> ClaudeSettings {
        let coreSettings = await scanCoreSettings()
        let localSettings = await scanLocalSettings()
        let keybindings = await scanKeybindings()
        let plugins = await scanPlugins()
        let skills = try await scanSkills()
        let commands = try await scanCommands()
        let sounds = try await scanSounds()

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

    func backup() async throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let backupDir = claudeDir
            .appending(path: "backups")
            .appending(path: "keepclaude_\(timestamp)")

        try await fileSystemService.createDirectory(at: backupDir)

        let filesToBackup: [(String, String)] = [
            (Constants.SyncTargets.settingsJSON, Constants.SyncTargets.settingsJSON),
            (Constants.SyncTargets.settingsLocalJSON, Constants.SyncTargets.settingsLocalJSON),
            (Constants.SyncTargets.keybindingsJSON, Constants.SyncTargets.keybindingsJSON),
        ]

        for (source, dest) in filesToBackup {
            let sourceURL = claudeDir.appending(path: source)
            if fileSystemService.fileExists(at: sourceURL) {
                let destURL = backupDir.appending(path: dest)
                try await fileSystemService.copyItem(from: sourceURL, to: destURL)
            }
        }

        // Backup plugin files
        for file in Constants.SyncTargets.pluginFiles {
            let sourceURL = claudeDir.appending(path: "plugins").appending(path: file)
            if fileSystemService.fileExists(at: sourceURL) {
                let destURL = backupDir.appending(path: "plugins").appending(path: file)
                try await fileSystemService.copyItem(from: sourceURL, to: destURL)
            }
        }

        // Backup skills
        let skillsDir = claudeDir.appending(path: Constants.SyncTargets.skillsDir)
        if fileSystemService.directoryExists(at: skillsDir) {
            let skillDirs = try await fileSystemService.listDirectories(in: skillsDir)
            for skillDir in skillDirs {
                let skillFile = skillDir.appending(path: "SKILL.md")
                if fileSystemService.fileExists(at: skillFile) {
                    let destURL = backupDir
                        .appending(path: Constants.SyncTargets.skillsDir)
                        .appending(path: skillDir.lastPathComponent)
                        .appending(path: "SKILL.md")
                    try await fileSystemService.copyItem(from: skillFile, to: destURL)
                }
            }
        }

        // Backup commands
        let commandsDir = claudeDir.appending(path: Constants.SyncTargets.commandsDir)
        if fileSystemService.directoryExists(at: commandsDir) {
            let files = try await fileSystemService.listContents(of: commandsDir)
            for file in files where file.pathExtension == "md" {
                let destURL = backupDir
                    .appending(path: Constants.SyncTargets.commandsDir)
                    .appending(path: file.lastPathComponent)
                try await fileSystemService.copyItem(from: file, to: destURL)
            }
        }

        return backupDir
    }

    func restore(_ settings: ClaudeSettings, categories: Set<SettingsCategory>) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        if categories.contains(.coreSettings), let core = settings.coreSettings {
            let data = PathSubstitution.restoreData(try encoder.encode(core))
            try await fileSystemService.writeData(
                data, to: claudeDir.appending(path: Constants.SyncTargets.settingsJSON)
            )
        }

        if categories.contains(.localSettings), let local = settings.localSettings {
            let data = PathSubstitution.restoreData(try encoder.encode(local))
            try await fileSystemService.writeData(
                data, to: claudeDir.appending(path: Constants.SyncTargets.settingsLocalJSON)
            )
        }

        if categories.contains(.keybindings), let kb = settings.keybindings {
            try await fileSystemService.writeData(
                PathSubstitution.restoreData(kb),
                to: claudeDir.appending(path: Constants.SyncTargets.keybindingsJSON)
            )
        }

        if categories.contains(.plugins), let plugins = settings.plugins {
            let pluginsDir = claudeDir.appending(path: Constants.SyncTargets.pluginsDir)
            try await fileSystemService.writeData(
                PathSubstitution.restoreData(try encoder.encode(plugins.installedPlugins)),
                to: pluginsDir.appending(path: "installed_plugins.json")
            )
            try await fileSystemService.writeData(
                PathSubstitution.restoreData(try encoder.encode(plugins.knownMarketplaces)),
                to: pluginsDir.appending(path: "known_marketplaces.json")
            )
            if let config = plugins.config {
                try await fileSystemService.writeData(
                    PathSubstitution.restoreData(try encoder.encode(config)),
                    to: pluginsDir.appending(path: "config.json")
                )
            }
            if let blocklist = plugins.blocklist {
                try await fileSystemService.writeData(
                    PathSubstitution.restoreData(try encoder.encode(blocklist)),
                    to: pluginsDir.appending(path: "blocklist.json")
                )
            }
        }

        if categories.contains(.skills) {
            for skill in settings.skills {
                let skillDir = claudeDir
                    .appending(path: Constants.SyncTargets.skillsDir)
                    .appending(path: skill.name)
                let data = PathSubstitution.restoreData(Data(skill.content.utf8))
                try await fileSystemService.writeData(
                    data, to: skillDir.appending(path: "SKILL.md")
                )
            }
        }

        if categories.contains(.commands) {
            for command in settings.commands {
                let data = PathSubstitution.restoreData(Data(command.content.utf8))
                try await fileSystemService.writeData(
                    data,
                    to: claudeDir
                        .appending(path: Constants.SyncTargets.commandsDir)
                        .appending(path: "\(command.name).md")
                )
            }
        }

        if categories.contains(.sounds) {
            for sound in settings.sounds {
                try await fileSystemService.writeData(
                    sound.data,
                    to: claudeDir
                        .appending(path: Constants.SyncTargets.soundDir)
                        .appending(path: sound.name)
                )
            }
        }
    }

    // MARK: - Private Scan Helpers

    private func scanCoreSettings() async -> CoreSettings? {
        let url = claudeDir.appending(path: Constants.SyncTargets.settingsJSON)
        guard let data = try? await fileSystemService.readData(at: url) else { return nil }
        return try? JSONDecoder().decode(CoreSettings.self, from: data)
    }

    private func scanLocalSettings() async -> CoreSettings? {
        let url = claudeDir.appending(path: Constants.SyncTargets.settingsLocalJSON)
        guard let data = try? await fileSystemService.readData(at: url) else { return nil }
        return try? JSONDecoder().decode(CoreSettings.self, from: data)
    }

    private func scanKeybindings() async -> Data? {
        let url = claudeDir.appending(path: Constants.SyncTargets.keybindingsJSON)
        return try? await fileSystemService.readData(at: url)
    }

    private func scanPlugins() async -> PluginSettings? {
        let pluginsDir = claudeDir.appending(path: Constants.SyncTargets.pluginsDir)

        let installedURL = pluginsDir.appending(path: "installed_plugins.json")
        guard let installedData = try? await fileSystemService.readData(at: installedURL),
              let installed = try? JSONDecoder().decode(InstalledPluginsFile.self, from: installedData) else {
            return nil
        }

        let marketplacesURL = pluginsDir.appending(path: "known_marketplaces.json")
        guard let marketplacesData = try? await fileSystemService.readData(at: marketplacesURL),
              let marketplaces = try? JSONDecoder().decode([String: KnownMarketplace].self, from: marketplacesData) else {
            return nil
        }

        var config: PluginConfig?
        let configURL = pluginsDir.appending(path: "config.json")
        if let data = try? await fileSystemService.readData(at: configURL) {
            config = try? JSONDecoder().decode(PluginConfig.self, from: data)
        }

        var blocklist: PluginBlocklist?
        let blocklistURL = pluginsDir.appending(path: "blocklist.json")
        if let data = try? await fileSystemService.readData(at: blocklistURL) {
            blocklist = try? JSONDecoder().decode(PluginBlocklist.self, from: data)
        }

        return PluginSettings(
            installedPlugins: installed,
            knownMarketplaces: marketplaces,
            config: config,
            blocklist: blocklist
        )
    }

    private func scanSkills() async throws -> [SkillDefinition] {
        let skillsDir = claudeDir.appending(path: Constants.SyncTargets.skillsDir)
        guard fileSystemService.directoryExists(at: skillsDir) else { return [] }

        var skills: [SkillDefinition] = []
        let dirs = try await fileSystemService.listDirectories(in: skillsDir)
        for dir in dirs {
            let skillFile = dir.appending(path: "SKILL.md")
            guard fileSystemService.fileExists(at: skillFile) else { continue }
            let data = try await fileSystemService.readData(at: skillFile)
            let content = String(data: data, encoding: .utf8) ?? ""
            skills.append(SkillDefinition(name: dir.lastPathComponent, content: content))
        }
        return skills
    }

    private func scanCommands() async throws -> [CommandDefinition] {
        let commandsDir = claudeDir.appending(path: Constants.SyncTargets.commandsDir)
        guard fileSystemService.directoryExists(at: commandsDir) else { return [] }

        var commands: [CommandDefinition] = []
        let files = try await fileSystemService.listContents(of: commandsDir)
        for file in files where file.pathExtension == "md" {
            let data = try await fileSystemService.readData(at: file)
            let content = String(data: data, encoding: .utf8) ?? ""
            let name = file.deletingPathExtension().lastPathComponent
            commands.append(CommandDefinition(name: name, content: content))
        }
        return commands
    }

    private func scanSounds() async throws -> [SoundFile] {
        let soundDir = claudeDir.appending(path: Constants.SyncTargets.soundDir)
        guard fileSystemService.directoryExists(at: soundDir) else { return [] }

        var sounds: [SoundFile] = []
        let files = try await fileSystemService.listContents(of: soundDir)
        for file in files where file.pathExtension == "aiff" || file.pathExtension == "wav" || file.pathExtension == "mp3" {
            let data = try await fileSystemService.readData(at: file)
            let size = try fileSystemService.fileSize(at: file)
            sounds.append(SoundFile(name: file.lastPathComponent, data: data, size: size))
        }
        return sounds
    }
}
