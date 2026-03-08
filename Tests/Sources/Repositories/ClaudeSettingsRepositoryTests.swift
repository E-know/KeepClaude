import Testing
import Foundation
@testable import KeepClaude

@Test func scanFindsSettingsJSON() async throws {
    let mockFS = MockFileSystemService()
    let claudeDir = URL(filePath: "/tmp/test-claude/")

    let settingsJSON = """
    {"language":"Korean"}
    """
    mockFS.files["/tmp/test-claude/settings.json"] = Data(settingsJSON.utf8)

    let repo = ClaudeSettingsRepository(fileSystemService: mockFS, claudeDirectory: claudeDir)
    let settings = try await repo.scan()

    #expect(settings.coreSettings != nil)
    #expect(settings.coreSettings?.language == "Korean")
}

@Test func scanReturnsNilForMissingFiles() async throws {
    let mockFS = MockFileSystemService()
    let claudeDir = URL(filePath: "/tmp/test-claude/")

    let repo = ClaudeSettingsRepository(fileSystemService: mockFS, claudeDirectory: claudeDir)
    let settings = try await repo.scan()

    #expect(settings.coreSettings == nil)
    #expect(settings.plugins == nil)
    #expect(settings.skills.isEmpty)
}

@Test func backupCreatesFiles() async throws {
    let mockFS = MockFileSystemService()
    let claudeDir = URL(filePath: "/tmp/test-claude/")

    mockFS.files["/tmp/test-claude/settings.json"] = Data("{}".utf8)

    let repo = ClaudeSettingsRepository(fileSystemService: mockFS, claudeDirectory: claudeDir)
    let backupURL = try await repo.backup()

    #expect(backupURL.path().contains("backups/keepclaude_"))
    // The backup directory should have been created
    #expect(mockFS.directories.contains(backupURL.path(percentEncoded: false)))
}

@Test func restoreWritesFiles() async throws {
    let mockFS = MockFileSystemService()
    let claudeDir = URL(filePath: "/tmp/test-claude/")

    let settings = ClaudeSettings(
        coreSettings: CoreSettings(language: "English"),
        skills: [SkillDefinition(name: "test-skill", content: "# Test Skill")]
    )

    let repo = ClaudeSettingsRepository(fileSystemService: mockFS, claudeDirectory: claudeDir)
    try await repo.restore(settings, categories: [.coreSettings, .skills])

    #expect(mockFS.files["/tmp/test-claude/settings.json"] != nil)
    #expect(mockFS.files["/tmp/test-claude/skills/test-skill/SKILL.md"] != nil)
}
