import Foundation

enum PathSubstitution {
    private static let homePlaceholder = "{{HOME}}"
    private static let claudeDirPlaceholder = "{{CLAUDE_DIR}}"

    static func sanitize(_ string: String) -> String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
        let claudeDir = homeDir + ".claude"

        var result = string
        // CLAUDE_DIR first (more specific)
        result = result.replacingOccurrences(of: claudeDir, with: claudeDirPlaceholder)
        result = result.replacingOccurrences(of: homeDir, with: homePlaceholder)
        return result
    }

    static func restore(_ string: String) -> String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
        let claudeDir = homeDir + ".claude"

        var result = string
        result = result.replacingOccurrences(of: claudeDirPlaceholder, with: claudeDir)
        result = result.replacingOccurrences(of: homePlaceholder, with: homeDir)
        return result
    }

    static func sanitizeData(_ data: Data) -> Data {
        guard let str = String(data: data, encoding: .utf8) else { return data }
        let sanitized = sanitize(str)
        return Data(sanitized.utf8)
    }

    static func restoreData(_ data: Data) -> Data {
        guard let str = String(data: data, encoding: .utf8) else { return data }
        let restored = restore(str)
        return Data(restored.utf8)
    }
}
