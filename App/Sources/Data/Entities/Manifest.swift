import Foundation

struct Manifest: Codable, Sendable, Equatable {
    let version: String
    let appVersion: String
    let syncedAt: String
    let syncedBy: String
    let platform: PlatformInfo
    let categories: [String: Bool]
    let summary: SyncSummary
}

struct PlatformInfo: Codable, Sendable, Equatable {
    let os: String
    let osVersion: String
}

struct SyncSummary: Codable, Sendable, Equatable {
    let pluginCount: Int
    let skillCount: Int
    let commandCount: Int
    let soundCount: Int
}
