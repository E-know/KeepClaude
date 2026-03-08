import Foundation

protocol GitHubPushWorking: Sendable {
    func push(categories: Set<SettingsCategory>, message: String) async throws
    func previewDiff(categories: Set<SettingsCategory>) async throws -> SettingsDiff
}
