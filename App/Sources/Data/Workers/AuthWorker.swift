import Foundation

struct AuthWorker: AuthWorking {
    private let authRepo: any AuthRepositoryProtocol

    init(authRepo: any AuthRepositoryProtocol = AuthRepository()) {
        self.authRepo = authRepo
    }

    func authenticate(token: String) async throws -> GitHubUser {
        let user = try await authRepo.validateToken(token)
        try authRepo.saveToken(token)
        return user
    }

    func loadSavedToken() throws -> String? {
        try authRepo.loadToken()
    }

    func deleteToken() throws {
        try authRepo.deleteToken()
    }

    func checkAuthStatus() async throws -> (isAuthenticated: Bool, user: GitHubUser?) {
        guard let token = try authRepo.loadToken() else {
            return (false, nil)
        }
        do {
            let user = try await authRepo.validateToken(token)
            return (true, user)
        } catch {
            return (false, nil)
        }
    }
}
