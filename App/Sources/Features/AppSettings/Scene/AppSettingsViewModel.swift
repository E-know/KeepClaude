import SwiftUI

@Observable
@MainActor
final class AppSettingsViewModel {
    var isAuthenticated = false
    var currentUser: GitHubUser?
    var tokenInput = ""
    var repoName = Constants.defaultRepoName
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
    var selectedLanguage: AppLanguage = .system
    var showRestartMessage = false
}
