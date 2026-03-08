import Testing
import Foundation
@testable import KeepClaude

@Test func pullWorkerFetchesWithOptionalToken() async throws {
    let mockGitHub = MockGitHubRepository()
    mockGitHub.fetchResult = ClaudeSettings(
        coreSettings: CoreSettings(language: "English")
    )

    let mockAuth = MockAuthRepository()
    // No token — public repo access

    let worker = GitHubPullWorker(
        githubRepo: mockGitHub,
        authRepo: mockAuth
    )

    let result = try await worker.fetchRemote(owner: "someone", repo: "claude-settings")
    #expect(result.coreSettings?.language == "English")
}

@Test func pullWorkerPassesTokenWhenAvailable() async throws {
    let mockGitHub = MockGitHubRepository()
    mockGitHub.fetchResult = ClaudeSettings()

    let mockAuth = MockAuthRepository()
    mockAuth.storedToken = "ghp_private"

    let worker = GitHubPullWorker(
        githubRepo: mockGitHub,
        authRepo: mockAuth
    )

    let result = try await worker.fetchRemote(owner: "user", repo: "claude-settings")
    #expect(result.coreSettings == nil)
}
