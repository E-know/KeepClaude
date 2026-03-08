import Foundation

struct SettingsTreeNode: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let icon: String
    let category: SettingsCategory?
    let fileCount: Int
    let totalSize: UInt64
    let children: [SettingsTreeNode]?

    var isExpandable: Bool {
        children != nil && !(children?.isEmpty ?? true)
    }

    var formattedSize: String {
        if totalSize == 0 { return "" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalSize))
    }
}

enum SettingsTreeMapper {
    static func map(_ settings: ClaudeSettings) -> [SettingsTreeNode] {
        var nodes: [SettingsTreeNode] = []

        if settings.coreSettings != nil {
            nodes.append(SettingsTreeNode(
                name: Constants.SyncTargets.settingsJSON,
                icon: "gearshape.fill",
                category: .coreSettings,
                fileCount: 1, totalSize: 0, children: nil
            ))
        }

        if settings.localSettings != nil {
            nodes.append(SettingsTreeNode(
                name: Constants.SyncTargets.settingsLocalJSON,
                icon: "gearshape",
                category: .localSettings,
                fileCount: 1, totalSize: 0, children: nil
            ))
        }

        if settings.keybindings != nil {
            nodes.append(SettingsTreeNode(
                name: Constants.SyncTargets.keybindingsJSON,
                icon: "keyboard",
                category: .keybindings,
                fileCount: 1, totalSize: UInt64(settings.keybindings?.count ?? 0),
                children: nil
            ))
        }

        if let plugins = settings.plugins {
            let pluginCount = plugins.installedPlugins.plugins.count
            let marketplaceCount = plugins.knownMarketplaces.count
            var pluginChildren: [SettingsTreeNode] = [
                SettingsTreeNode(
                    name: "installed_plugins.json",
                    icon: "doc.text",
                    category: nil,
                    fileCount: pluginCount, totalSize: 0, children: nil
                ),
                SettingsTreeNode(
                    name: "known_marketplaces.json",
                    icon: "doc.text",
                    category: nil,
                    fileCount: marketplaceCount, totalSize: 0, children: nil
                ),
            ]
            if plugins.config != nil {
                pluginChildren.append(SettingsTreeNode(
                    name: "config.json", icon: "doc.text",
                    category: nil, fileCount: 1, totalSize: 0, children: nil
                ))
            }
            if plugins.blocklist != nil {
                pluginChildren.append(SettingsTreeNode(
                    name: "blocklist.json", icon: "doc.text",
                    category: nil, fileCount: 1, totalSize: 0, children: nil
                ))
            }
            nodes.append(SettingsTreeNode(
                name: "plugins/",
                icon: "puzzlepiece.fill",
                category: .plugins,
                fileCount: pluginChildren.count, totalSize: 0,
                children: pluginChildren
            ))
        }

        if !settings.skills.isEmpty {
            let skillChildren = settings.skills.map { skill in
                SettingsTreeNode(
                    name: "\(skill.name)/SKILL.md",
                    icon: "doc.text",
                    category: nil,
                    fileCount: 1,
                    totalSize: UInt64(skill.content.utf8.count),
                    children: nil
                )
            }
            nodes.append(SettingsTreeNode(
                name: "skills/",
                icon: "sparkles",
                category: .skills,
                fileCount: settings.skills.count, totalSize: 0,
                children: skillChildren
            ))
        }

        if !settings.commands.isEmpty {
            let commandChildren = settings.commands.map { cmd in
                SettingsTreeNode(
                    name: "\(cmd.name).md",
                    icon: "doc.text",
                    category: nil,
                    fileCount: 1,
                    totalSize: UInt64(cmd.content.utf8.count),
                    children: nil
                )
            }
            nodes.append(SettingsTreeNode(
                name: "commands/",
                icon: "terminal.fill",
                category: .commands,
                fileCount: settings.commands.count, totalSize: 0,
                children: commandChildren
            ))
        }

        if !settings.sounds.isEmpty {
            let soundChildren = settings.sounds.map { sound in
                SettingsTreeNode(
                    name: sound.name,
                    icon: "speaker.wave.2",
                    category: nil,
                    fileCount: 1,
                    totalSize: sound.size,
                    children: nil
                )
            }
            let totalSoundSize = settings.sounds.reduce(0 as UInt64) { $0 + $1.size }
            nodes.append(SettingsTreeNode(
                name: "sound/",
                icon: "speaker.wave.2.fill",
                category: .sounds,
                fileCount: settings.sounds.count,
                totalSize: totalSoundSize,
                children: soundChildren
            ))
        }

        return nodes
    }
}
