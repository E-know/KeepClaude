import Foundation

struct GitHubPullWorker: GitHubPullWorking {
    private let githubRepo: any GitHubRepositoryProtocol
    private let authRepo: any AuthRepositoryProtocol

    init(
        githubRepo: any GitHubRepositoryProtocol = GitHubRepository(),
        authRepo: any AuthRepositoryProtocol = AuthRepository()
    ) {
        self.githubRepo = githubRepo
        self.authRepo = authRepo
    }

    func fetchRemote(owner: String, repo: String) async throws -> ClaudeSettings {
        let token = try? authRepo.loadToken()
        return try await githubRepo.fetchRemoteSettings(owner: owner, repo: repo, token: token)
    }

    func fetchManifest(owner: String, repo: String) async throws -> Manifest? {
        let token = try? authRepo.loadToken()
        let githubService = GitHubAPIService()
        let endpoint = GitHubEndpoint.getContents(owner: owner, repo: repo, path: Constants.manifestFileName, token: token)

        do {
            let item: GitHubDTO.ContentItem = try await githubService.request(endpoint)
            guard let content = item.content else { return nil }
            let cleaned = content.replacingOccurrences(of: "\n", with: "")
            guard let data = Data(base64Encoded: cleaned) else { return nil }
            return try JSONDecoder().decode(Manifest.self, from: data)
        } catch {
            return nil
        }
    }
}
