import Foundation

struct PluginSettings: Codable, Sendable, Equatable {
    var installedPlugins: InstalledPluginsFile
    var knownMarketplaces: [String: KnownMarketplace]
    var config: PluginConfig?
    var blocklist: PluginBlocklist?
}

struct InstalledPluginsFile: Codable, Sendable, Equatable {
    var version: Int
    var plugins: [String: [InstalledPlugin]]
}

struct InstalledPlugin: Codable, Sendable, Equatable {
    var scope: String
    var installPath: String
    var version: String
    var installedAt: String
    var lastUpdated: String
    var gitCommitSha: String?
}

struct KnownMarketplace: Codable, Sendable, Equatable {
    var source: MarketplaceSource
    var installLocation: String
    var lastUpdated: String
}

struct PluginConfig: Codable, Sendable, Equatable {
    var repositories: [String: String]?
}

struct PluginBlocklist: Codable, Sendable, Equatable {
    var fetchedAt: String
    var plugins: [BlockedPlugin]
}

struct BlockedPlugin: Codable, Sendable, Equatable {
    var plugin: String
    var addedAt: String
    var reason: String
    var text: String

    enum CodingKeys: String, CodingKey {
        case plugin
        case addedAt = "added_at"
        case reason
        case text
    }
}
