import Testing
import Foundation
@testable import KeepClaude

@Test func saveAndLoadToken() throws {
    let mockKeychain = MockKeychainService()
    let mockGitHub = MockGitHubAPIService()
    let repo = AuthRepository(keychainService: mockKeychain, githubService: mockGitHub)

    try repo.saveToken("ghp_test123")
    let loaded = try repo.loadToken()

    #expect(loaded == "ghp_test123")
}

@Test func deleteToken() throws {
    let mockKeychain = MockKeychainService()
    let mockGitHub = MockGitHubAPIService()
    let repo = AuthRepository(keychainService: mockKeychain, githubService: mockGitHub)

    try repo.saveToken("ghp_test123")
    try repo.deleteToken()
    let loaded = try repo.loadToken()

    #expect(loaded == nil)
}
