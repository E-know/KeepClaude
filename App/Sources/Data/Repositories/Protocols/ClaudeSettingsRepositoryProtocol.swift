import Foundation

protocol ClaudeSettingsRepositoryProtocol: Sendable {
    func scan() async throws -> ClaudeSettings
    func backup() async throws -> URL
    func restore(_ settings: ClaudeSettings, categories: Set<SettingsCategory>) async throws
}
