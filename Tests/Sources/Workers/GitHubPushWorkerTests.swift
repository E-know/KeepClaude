import Testing
import Foundation
@testable import KeepClaude

@Test func pushWorkerRequiresAuth() async {
    let mockSettings = MockClaudeSettingsRepository()
    let mockGitHub = MockGitHubRepository()
    let mockAuth = MockAuthRepository()
    // No token stored

    let worker = GitHubPushWorker(
        settingsRepo: mockSettings,
        githubRepo: mockGitHub,
        authRepo: mockAuth
    )

    do {
        try await worker.push(categories: [.coreSettings], message: "test")
        Issue.record("Expected AuthError.notAuthenticated")
    } catch {
        #expect(error is AuthError)
    }
}

@Test func pushWorkerCallsRepoMethods() async throws {
    let mockSettings = MockClaudeSettingsRepository()
    mockSettings.scanResult = ClaudeSettings(
        coreSettings: CoreSettings(language: "Korean")
    )

    let mockGitHub = MockGitHubRepository()
    mockGitHub.ensureRepoResult = GitHubRepo(
        id: 1, name: "claude-settings",
        fullName: "user/claude-settings",
        isPrivate: false, htmlUrl: "https://github.com/user/claude-settings",
        defaultBranch: "main"
    )

    let mockAuth = MockAuthRepository()
    mockAuth.storedToken = "ghp_test"
    mockAuth.validationUser = GitHubUser(login: "user", id: 1, avatarUrl: nil, name: "User")

    let worker = GitHubPushWorker(
        settingsRepo: mockSettings,
        githubRepo: mockGitHub,
        authRepo: mockAuth
    )

    try await worker.push(categories: [.coreSettings], message: "sync")

    #expect(mockGitHub.pushedSettings != nil)
    #expect(mockGitHub.pushedSettings?.coreSettings != nil)
}
