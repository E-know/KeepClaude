import Foundation

struct GitHubUser: Codable, Sendable, Equatable {
    let login: String
    let id: Int
    let avatarUrl: String?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case login, id, name
        case avatarUrl = "avatar_url"
    }
}
