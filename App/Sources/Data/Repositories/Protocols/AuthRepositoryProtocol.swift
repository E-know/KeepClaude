import Foundation

protocol AuthRepositoryProtocol: Sendable {
    func saveToken(_ token: String) throws
    func loadToken() throws -> String?
    func deleteToken() throws
    func validateToken(_ token: String) async throws -> GitHubUser
}
