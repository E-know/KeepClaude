import Foundation

struct AppConfig: Codable, Sendable {
    var defaultRepoName: String = Constants.defaultRepoName
}
