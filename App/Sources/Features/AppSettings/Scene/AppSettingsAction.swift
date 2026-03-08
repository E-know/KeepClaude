import Foundation

enum AppSettingsAction: Sendable {
    case onAppear
    case connectGitHub(token: String)
    case disconnectGitHub
    case updateRepoName(String)
}
