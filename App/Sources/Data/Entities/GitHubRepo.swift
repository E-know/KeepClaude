import Foundation

struct GitHubRepo: Codable, Sendable, Equatable {
    let id: Int
    let name: String
    let fullName: String
    let isPrivate: Bool
    let htmlUrl: String
    let defaultBranch: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case fullName = "full_name"
        case isPrivate = "private"
        case htmlUrl = "html_url"
        case defaultBranch = "default_branch"
    }
}
