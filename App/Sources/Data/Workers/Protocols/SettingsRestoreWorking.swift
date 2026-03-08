import Foundation

protocol SettingsRestoreWorking: Sendable {
    func backup() async throws -> URL
    func restore(_ settings: ClaudeSettings, categories: Set<SettingsCategory>) async throws
}
