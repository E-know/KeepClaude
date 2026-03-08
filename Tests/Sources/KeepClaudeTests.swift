import Testing
@testable import KeepClaude

@Test func settingsCategoryDefaults() {
    let enabled = SettingsCategory.allCases.filter(\.isDefaultEnabled)
    #expect(enabled.contains(.coreSettings))
    #expect(enabled.contains(.plugins))
    #expect(enabled.contains(.skills))
    #expect(enabled.contains(.commands))
    #expect(!enabled.contains(.localSettings))
    #expect(!enabled.contains(.keybindings))
    #expect(!enabled.contains(.sounds))
}

@Test func claudeSettingsFilter() {
    var settings = ClaudeSettings(
        coreSettings: CoreSettings(language: "Korean"),
        skills: [SkillDefinition(name: "commit", content: "test")],
        commands: [CommandDefinition(name: "commit", content: "test")]
    )

    settings.filter(by: [.coreSettings])

    #expect(settings.coreSettings != nil)
    #expect(settings.skills.isEmpty)
    #expect(settings.commands.isEmpty)
}

@Test func claudeSettingsAvailableCategories() {
    let settings = ClaudeSettings(
        coreSettings: CoreSettings(language: "Korean"),
        skills: [SkillDefinition(name: "test", content: "content")]
    )

    let categories = settings.availableCategories()
    #expect(categories.contains(.coreSettings))
    #expect(categories.contains(.skills))
    #expect(!categories.contains(.plugins))
    #expect(!categories.contains(.sounds))
}
