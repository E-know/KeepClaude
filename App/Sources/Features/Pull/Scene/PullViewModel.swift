import SwiftUI

@Observable
@MainActor
final class PullViewModel {
    var repoURL = ""

    var parsedRepo: (owner: String, repo: String)? {
        let cleaned = repoURL
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".git", with: "")

        let components: [String]
        if let url = URL(string: cleaned), let host = url.host,
           host.contains("github.com") {
            components = url.pathComponents.filter { $0 != "/" }
        } else {
            components = cleaned.split(separator: "/").map(String.init)
        }

        guard components.count >= 2 else { return nil }
        let owner = components[components.count - 2]
        let repo = components[components.count - 1]
        guard !owner.isEmpty, !repo.isEmpty else { return nil }
        return (owner, repo)
    }
    var manifest: Manifest?
    var restoreOptions: [RestoreOption] = []
    var isLoading = false
    var isFetched = false
    var isRestoring = false
    var progressMessage = ""
    var errorMessage: String?
    var restoreSuccess = false
    var backupURL: URL?
}
