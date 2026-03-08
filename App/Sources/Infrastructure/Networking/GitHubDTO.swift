import Foundation

enum GitHubDTO {
    struct ContentItem: Codable, Sendable {
        let name: String
        let path: String
        let sha: String
        let size: Int?
        let type: String
        let content: String?
        let encoding: String?
        let downloadUrl: String?

        enum CodingKeys: String, CodingKey {
            case name, path, sha, size, type, content, encoding
            case downloadUrl = "download_url"
        }
    }

    struct BlobResponse: Codable, Sendable {
        let sha: String
        let url: String
    }

    struct TreeResponse: Codable, Sendable {
        let sha: String
        let url: String
    }

    struct CommitResponse: Codable, Sendable {
        let sha: String
        let url: String
    }

    struct RefResponse: Codable, Sendable {
        let ref: String
        let object: RefObject
    }

    struct RefObject: Codable, Sendable {
        let sha: String
        let type: String
    }

    struct CommitDetail: Codable, Sendable {
        let sha: String
        let tree: TreeRef
    }

    struct TreeRef: Codable, Sendable {
        let sha: String
    }

    struct CreateRepoRequest: Codable, Sendable {
        let name: String
        let description: String?
        let isPrivate: Bool
        let autoInit: Bool

        enum CodingKeys: String, CodingKey {
            case name, description
            case isPrivate = "private"
            case autoInit = "auto_init"
        }
    }
}
