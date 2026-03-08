import Foundation

enum DashboardResponse: Sendable {
    case scanned(ClaudeSettings)
    case loading(Bool)
}
