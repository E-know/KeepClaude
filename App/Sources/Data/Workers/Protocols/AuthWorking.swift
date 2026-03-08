import Foundation

protocol AuthWorking: Sendable {
    func authenticate(token: String) async throws -> GitHubUser
    func loadSavedToken() throws -> String?
    func deleteToken() throws
    func checkAuthStatus() async throws -> (isAuthenticated: Bool, user: GitHubUser?)
}
