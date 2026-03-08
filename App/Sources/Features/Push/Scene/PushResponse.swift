import Foundation

enum PushResponse: Sendable {
    case categoriesLoaded(ClaudeSettings, isAuthenticated: Bool)
    case pushCompleted
    case loading(Bool)
    case pushProgress(String)
}
