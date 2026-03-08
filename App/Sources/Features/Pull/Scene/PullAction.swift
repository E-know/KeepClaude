import Foundation

enum PullAction: Sendable {
    case onAppear
    case fetchRemote(owner: String, repo: String)
    case toggleCategory(SettingsCategory)
    case executeRestore(Set<SettingsCategory>)
}
