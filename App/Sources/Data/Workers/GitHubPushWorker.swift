import Foundation

struct GitHubPushWorker: GitHubPushWorking {
    private let settingsRepo: any ClaudeSettingsRepositoryProtocol
    private let githubRepo: any GitHubRepositoryProtocol
    private let authRepo: any AuthRepositoryProtocol

    init(
        settingsRepo: any ClaudeSettingsRepositoryProtocol = ClaudeSettingsRepository(),
        githubRepo: any GitHubRepositoryProtocol = GitHubRepository(),
        authRepo: any AuthRepositoryProtocol = AuthRepository()
    ) {
        self.settingsRepo = settingsRepo
        self.githubRepo = githubRepo
        self.authRepo = authRepo
    }

    func push(categories: Set<SettingsCategory>, message: String) async throws {
        guard let token = try authRepo.loadToken() else {
            throw AuthError.notAuthenticated
        }
        let user = try await authRepo.validateToken(token)
        let repo = try await githubRepo.ensureRepoExists(
            name: Constants.defaultRepoName, token: token
        )

        var settings = try await settingsRepo.scan()
        settings.filter(by: categories)

        try await githubRepo.pushSettings(
            settings, owner: user.login,
            repo: repo.name,
            branch: repo.defaultBranch,
            message: message, token: token
        )
    }

    func previewDiff(categories: Set<SettingsCategory>) async throws -> SettingsDiff {
        guard let token = try authRepo.loadToken() else {
            throw AuthError.notAuthenticated
        }
        let user = try await authRepo.validateToken(token)
        var local = try await settingsRepo.scan()
        local.filter(by: categories)
        return try await githubRepo.compareWithRemote(
            local: local, owner: user.login,
            repo: Constants.defaultRepoName, token: token
        )
    }
}
