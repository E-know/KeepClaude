import Foundation

protocol KeychainServicing: Sendable {
    func save(token: String, for account: String) throws
    func load(for account: String) throws -> String?
    func delete(for account: String) throws
}
