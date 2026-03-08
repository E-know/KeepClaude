import Foundation

struct SettingsScanWorker: SettingsScanWorking {
    private let settingsRepository: any ClaudeSettingsRepositoryProtocol

    init(settingsRepository: any ClaudeSettingsRepositoryProtocol = ClaudeSettingsRepository()) {
        self.settingsRepository = settingsRepository
    }

    func scanSettings() async throws -> ClaudeSettings {
        try await settingsRepository.scan()
    }
}
