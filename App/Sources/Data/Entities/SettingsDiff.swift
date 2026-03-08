import Foundation

enum DiffStatus: String, Sendable {
    case added
    case modified
    case deleted
    case unchanged
}

struct FileDiff: Sendable, Equatable, Identifiable {
    let id = UUID()
    let path: String
    let status: DiffStatus
    let localSize: UInt64?
    let remoteSize: UInt64?

    static func == (lhs: FileDiff, rhs: FileDiff) -> Bool {
        lhs.path == rhs.path && lhs.status == rhs.status
    }
}

struct SettingsDiff: Sendable, Equatable {
    let diffs: [FileDiff]

    var hasChanges: Bool {
        diffs.contains { $0.status != .unchanged }
    }

    func filtered(by category: SettingsCategory) -> [FileDiff] {
        let prefix: String = switch category {
        case .coreSettings: Constants.SyncTargets.settingsJSON
        case .localSettings: Constants.SyncTargets.settingsLocalJSON
        case .keybindings: Constants.SyncTargets.keybindingsJSON
        case .plugins: Constants.SyncTargets.pluginsDir
        case .skills: Constants.SyncTargets.skillsDir
        case .commands: Constants.SyncTargets.commandsDir
        case .sounds: Constants.SyncTargets.soundDir
        }
        return diffs.filter { $0.path.hasPrefix(prefix) }
    }

    static func == (lhs: SettingsDiff, rhs: SettingsDiff) -> Bool {
        lhs.diffs == rhs.diffs
    }
}
