import Foundation

struct SettingsRestoreWorker: SettingsRestoreWorking {
    private let settingsRepo: any ClaudeSettingsRepositoryProtocol

    init(settingsRepo: any ClaudeSettingsRepositoryProtocol = ClaudeSettingsRepository()) {
        self.settingsRepo = settingsRepo
    }

    func backup() async throws -> URL {
        try await settingsRepo.backup()
    }

    func restore(_ settings: ClaudeSettings, categories: Set<SettingsCategory>) async throws {
        _ = try await settingsRepo.backup()
        try await settingsRepo.restore(settings, categories: categories)
    }
}
