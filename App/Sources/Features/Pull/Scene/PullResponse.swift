import Foundation

enum PullResponse: Sendable {
    case loading(Bool)
    case manifestLoaded(Manifest?)
    case remoteSettingsLoaded(ClaudeSettings, localCategories: Set<SettingsCategory>)
    case restoreCompleted(backupURL: URL)
    case restoreProgress(String)
}
