import Foundation
@testable import KeepClaude

final class MockKeychainService: KeychainServicing, @unchecked Sendable {
    var store: [String: String] = [:]

    func save(token: String, for account: String) throws {
        store[account] = token
    }

    func load(for account: String) throws -> String? {
        store[account]
    }

    func delete(for account: String) throws {
        store.removeValue(forKey: account)
    }
}
