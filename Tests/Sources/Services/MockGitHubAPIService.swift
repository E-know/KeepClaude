import Foundation
@testable import KeepClaude

final class MockGitHubAPIService: GitHubAPIServicing, @unchecked Sendable {
    var responses: [String: Any] = [:]
    var rawResponses: [String: Data] = [:]
    var requestedPaths: [String] = []

    func request<T: Decodable & Sendable>(_ endpoint: GitHubEndpoint) async throws -> T {
        requestedPaths.append(endpoint.path)
        if let response = responses[endpoint.path] as? T {
            return response
        }
        throw NetworkError.notFound
    }

    func requestRaw(_ endpoint: GitHubEndpoint) async throws -> Data {
        requestedPaths.append(endpoint.path)
        if let data = rawResponses[endpoint.path] {
            return data
        }
        throw NetworkError.notFound
    }
}
