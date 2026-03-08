import Foundation

struct ClaudeSettings: Codable, Sendable, Equatable {
    var coreSettings: CoreSettings?
    var localSettings: CoreSettings?
    var keybindings: Data?
    var plugins: PluginSettings?
    var skills: [SkillDefinition]
    var commands: [CommandDefinition]
    var sounds: [SoundFile]

    init(
        coreSettings: CoreSettings? = nil,
        localSettings: CoreSettings? = nil,
        keybindings: Data? = nil,
        plugins: PluginSettings? = nil,
        skills: [SkillDefinition] = [],
        commands: [CommandDefinition] = [],
        sounds: [SoundFile] = []
    ) {
        self.coreSettings = coreSettings
        self.localSettings = localSettings
        self.keybindings = keybindings
        self.plugins = plugins
        self.skills = skills
        self.commands = commands
        self.sounds = sounds
    }

    mutating func filter(by categories: Set<SettingsCategory>) {
        if !categories.contains(.coreSettings) { coreSettings = nil }
        if !categories.contains(.localSettings) { localSettings = nil }
        if !categories.contains(.keybindings) { keybindings = nil }
        if !categories.contains(.plugins) { plugins = nil }
        if !categories.contains(.skills) { skills = [] }
        if !categories.contains(.commands) { commands = [] }
        if !categories.contains(.sounds) { sounds = [] }
    }

    func availableCategories() -> Set<SettingsCategory> {
        var result = Set<SettingsCategory>()
        if coreSettings != nil { result.insert(.coreSettings) }
        if localSettings != nil { result.insert(.localSettings) }
        if keybindings != nil { result.insert(.keybindings) }
        if plugins != nil { result.insert(.plugins) }
        if !skills.isEmpty { result.insert(.skills) }
        if !commands.isEmpty { result.insert(.commands) }
        if !sounds.isEmpty { result.insert(.sounds) }
        return result
    }
}
