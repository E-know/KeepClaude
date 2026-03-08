import Foundation

struct AuthRepository: AuthRepositoryProtocol {
    private let keychainService: any KeychainServicing
    private let githubService: any GitHubAPIServicing

    init(
        keychainService: any KeychainServicing = KeychainService(),
        githubService: any GitHubAPIServicing = GitHubAPIService()
    ) {
        self.keychainService = keychainService
        self.githubService = githubService
    }

    func saveToken(_ token: String) throws {
        try keychainService.save(token: token, for: Constants.keychainAccountName)
    }

    func loadToken() throws -> String? {
        try keychainService.load(for: Constants.keychainAccountName)
    }

    func deleteToken() throws {
        try keychainService.delete(for: Constants.keychainAccountName)
    }

    func validateToken(_ token: String) async throws -> GitHubUser {
        try await githubService.request(.getUser(token: token))
    }
}
