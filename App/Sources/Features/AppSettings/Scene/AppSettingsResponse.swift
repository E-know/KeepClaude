import Foundation

enum AppSettingsResponse: Sendable {
    case authStatus(isAuthenticated: Bool, user: GitHubUser?)
    case connected(GitHubUser)
    case disconnected
    case loading(Bool)
}
