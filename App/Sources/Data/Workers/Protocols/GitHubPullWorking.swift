import Foundation

protocol GitHubPullWorking: Sendable {
    func fetchRemote(owner: String, repo: String) async throws -> ClaudeSettings
    func fetchManifest(owner: String, repo: String) async throws -> Manifest?
}
