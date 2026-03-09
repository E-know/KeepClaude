import Foundation

enum SettingsCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case coreSettings
    case localSettings
    case keybindings
    case plugins
    case skills
    case commands
    case sounds

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .coreSettings: String(localized: "핵심 설정")
        case .localSettings: String(localized: "로컬 설정")
        case .keybindings: String(localized: "키바인딩")
        case .plugins: String(localized: "플러그인")
        case .skills: String(localized: "스킬")
        case .commands: String(localized: "커맨드")
        case .sounds: String(localized: "사운드")
        }
    }

    var iconName: String {
        switch self {
        case .coreSettings: "gearshape.fill"
        case .localSettings: "gearshape"
        case .keybindings: "keyboard"
        case .plugins: "puzzlepiece.fill"
        case .skills: "sparkles"
        case .commands: "terminal.fill"
        case .sounds: "speaker.wave.2.fill"
        }
    }

    var isDefaultEnabled: Bool {
        switch self {
        case .coreSettings, .plugins, .skills, .commands:
            true
        case .localSettings, .keybindings, .sounds:
            false
        }
    }
}
