import Foundation

protocol GitHubRepositoryProtocol: Sendable {
    func fetchRemoteSettings(owner: String, repo: String, token: String?) async throws -> ClaudeSettings
    func pushSettings(_ settings: ClaudeSettings, owner: String, repo: String, branch: String, message: String, token: String) async throws
    func compareWithRemote(local: ClaudeSettings, owner: String, repo: String, token: String?) async throws -> SettingsDiff
    func ensureRepoExists(name: String, token: String) async throws -> GitHubRepo
}
