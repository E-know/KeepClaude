import Foundation

struct GitHubEndpoint: Sendable {
    let path: String
    let method: HTTPMethod
    let body: Data?
    let token: String?

    enum HTTPMethod: String, Sendable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
    }

    func urlRequest() throws -> URLRequest {
        guard let url = URL(string: Constants.githubAPIBaseURL + path) else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}

// MARK: - Factory Methods

extension GitHubEndpoint {
    static func getUser(token: String) -> GitHubEndpoint {
        GitHubEndpoint(path: "/user", method: .get, body: nil, token: token)
    }

    static func getRepo(owner: String, repo: String, token: String?) -> GitHubEndpoint {
        GitHubEndpoint(path: "/repos/\(owner)/\(repo)", method: .get, body: nil, token: token)
    }

    static func createRepo(name: String, isPrivate: Bool, token: String) -> GitHubEndpoint {
        let body = GitHubDTO.CreateRepoRequest(
            name: name,
            description: "Claude Code settings backup by KeepClaude",
            isPrivate: isPrivate,
            autoInit: true
        )
        let data = try? JSONEncoder().encode(body)
        return GitHubEndpoint(path: "/user/repos", method: .post, body: data, token: token)
    }

    static func getContents(owner: String, repo: String, path: String, token: String?) -> GitHubEndpoint {
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        return GitHubEndpoint(
            path: "/repos/\(owner)/\(repo)/contents/\(encodedPath)",
            method: .get, body: nil, token: token
        )
    }

    static func createBlob(owner: String, repo: String, content: String, encoding: String, token: String) -> GitHubEndpoint {
        let body: [String: String] = ["content": content, "encoding": encoding]
        let data = try? JSONEncoder().encode(body)
        return GitHubEndpoint(
            path: "/repos/\(owner)/\(repo)/git/blobs",
            method: .post, body: data, token: token
        )
    }

    static func createTree(owner: String, repo: String, baseTree: String?, tree: [[String: String]], token: String) -> GitHubEndpoint {
        var body: [String: Any] = ["tree": tree]
        if let baseTree {
            body["base_tree"] = baseTree
        }
        let data = try? JSONSerialization.data(withJSONObject: body)
        return GitHubEndpoint(
            path: "/repos/\(owner)/\(repo)/git/trees",
            method: .post, body: data, token: token
        )
    }

    static func createCommit(owner: String, repo: String, message: String, tree: String, parents: [String], token: String) -> GitHubEndpoint {
        let body: [String: Any] = [
            "message": message,
            "tree": tree,
            "parents": parents
        ]
        let data = try? JSONSerialization.data(withJSONObject: body)
        return GitHubEndpoint(
            path: "/repos/\(owner)/\(repo)/git/commits",
            method: .post, body: data, token: token
        )
    }

    static func getRef(owner: String, repo: String, ref: String, token: String?) -> GitHubEndpoint {
        GitHubEndpoint(
            path: "/repos/\(owner)/\(repo)/git/ref/\(ref)",
            method: .get, body: nil, token: token
        )
    }

    static func updateRef(owner: String, repo: String, ref: String, sha: String, token: String) -> GitHubEndpoint {
        let body: [String: Any] = ["sha": sha, "force": false]
        let data = try? JSONSerialization.data(withJSONObject: body)
        return GitHubEndpoint(
            path: "/repos/\(owner)/\(repo)/git/refs/\(ref)",
            method: .patch, body: data, token: token
        )
    }
}
