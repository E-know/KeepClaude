import Foundation

protocol SettingsScanWorking: Sendable {
    func scanSettings() async throws -> ClaudeSettings
}
