import Foundation

struct CoreSettings: Codable, Sendable, Equatable {
    var env: [String: String]?
    var permissions: PermissionSettings?
    var hooks: [String: [HookGroup]]?
    var statusLine: StatusLineConfig?
    var enabledPlugins: [String: Bool]?
    var extraKnownMarketplaces: [String: MarketplaceInfo]?
    var language: String?
    var effortLevel: String?
}

struct PermissionSettings: Codable, Sendable, Equatable {
    var allow: [String]?
    var defaultMode: String?
}

struct HookGroup: Codable, Sendable, Equatable {
    var matcher: String
    var hooks: [HookAction]
}

struct HookAction: Codable, Sendable, Equatable {
    var type: String
    var command: String
}

struct StatusLineConfig: Codable, Sendable, Equatable {
    var type: String
    var command: String
}

struct MarketplaceInfo: Codable, Sendable, Equatable {
    var source: MarketplaceSource
}

struct MarketplaceSource: Codable, Sendable, Equatable {
    var source: String
    var url: String?
    var repo: String?
}
