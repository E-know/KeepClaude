import Foundation

enum PushAction: Sendable {
    case onAppear
    case toggleCategory(SettingsCategory)
    case updateCommitMessage(String)
    case executePush(categories: Set<SettingsCategory>, message: String)
}
