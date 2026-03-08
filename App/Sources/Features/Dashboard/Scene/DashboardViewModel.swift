import SwiftUI

@Observable
@MainActor
final class DashboardViewModel {
    var settingsTree: [SettingsTreeNode] = []
    var isLoading = false
    var errorMessage: String?
    var claudeDirExists = false
}
