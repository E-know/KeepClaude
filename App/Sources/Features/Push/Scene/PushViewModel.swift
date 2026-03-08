import SwiftUI

@Observable
@MainActor
final class PushViewModel {
    var availableCategories: [SettingsCategory] = []
    var selectedCategories: Set<SettingsCategory> = []
    var commitMessage = ""
    var isLoading = false
    var isPushing = false
    var progressMessage = ""
    var errorMessage: String?
    var pushSuccess = false
    var isAuthenticated = false
}
