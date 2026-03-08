import Testing
import Foundation
@testable import KeepClaude

@Test func scanWorkerDelegatesToRepository() async throws {
    let mockRepo = MockClaudeSettingsRepository()
    mockRepo.scanResult = ClaudeSettings(
        coreSettings: CoreSettings(language: "Korean"),
        skills: [SkillDefinition(name: "test", content: "content")]
    )

    let worker = SettingsScanWorker(settingsRepository: mockRepo)
    let result = try await worker.scanSettings()

    #expect(result.coreSettings?.language == "Korean")
    #expect(result.skills.count == 1)
    #expect(result.skills.first?.name == "test")
}
