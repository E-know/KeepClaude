import Foundation
@testable import KeepClaude

final class MockClaudeSettingsRepository: ClaudeSettingsRepositoryProtocol, @unchecked Sendable {
    var scanResult: ClaudeSettings = ClaudeSettings()
    var backupURL: URL = URL(filePath: "/tmp/backup")
    var restoredSettings: ClaudeSettings?
    var restoredCategories: Set<SettingsCategory>?

    func scan() async throws -> ClaudeSettings {
        scanResult
    }

    func backup() async throws -> URL {
        backupURL
    }

    func restore(_ settings: ClaudeSettings, categories: Set<SettingsCategory>) async throws {
        restoredSettings = settings
        restoredCategories = categories
    }
}

final class MockAuthRepository: AuthRepositoryProtocol, @unchecked Sendable {
    var storedToken: String?
    var validationUser: GitHubUser?
    var shouldFailValidation = false

    func saveToken(_ token: String) throws {
        storedToken = token
    }

    func loadToken() throws -> String? {
        storedToken
    }

    func deleteToken() throws {
        storedToken = nil
    }

    func validateToken(_ token: String) async throws -> GitHubUser {
        if shouldFailValidation {
            throw AuthError.invalidToken
        }
        guard let user = validationUser else {
            throw AuthError.invalidToken
        }
        return user
    }
}

final class MockGitHubRepository: GitHubRepositoryProtocol, @unchecked Sendable {
    var ensureRepoResult: GitHubRepo?
    var pushedSettings: ClaudeSettings?
    var fetchResult: ClaudeSettings = ClaudeSettings()
    var compareResult: SettingsDiff = SettingsDiff(diffs: [])

    func ensureRepoExists(name: String, token: String) async throws -> GitHubRepo {
        guard let repo = ensureRepoResult else {
            throw NetworkError.notFound
        }
        return repo
    }

    func pushSettings(_ settings: ClaudeSettings, owner: String, repo: String, branch: String, message: String, token: String) async throws {
        pushedSettings = settings
    }

    func fetchRemoteSettings(owner: String, repo: String, token: String?) async throws -> ClaudeSettings {
        fetchResult
    }

    func compareWithRemote(local: ClaudeSettings, owner: String, repo: String, token: String?) async throws -> SettingsDiff {
        compareResult
    }
}
