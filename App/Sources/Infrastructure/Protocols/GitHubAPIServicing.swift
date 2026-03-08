import Foundation

protocol GitHubAPIServicing: Sendable {
    func request<T: Decodable & Sendable>(_ endpoint: GitHubEndpoint) async throws -> T
    func requestRaw(_ endpoint: GitHubEndpoint) async throws -> Data
}
