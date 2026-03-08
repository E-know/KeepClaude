import Testing
import Foundation
@testable import KeepClaude

@Test func pathSubstitutionSanitizeAndRestore() {
    let homeDir = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
    let original = "\(homeDir).claude/settings.json"
    let sanitized = PathSubstitution.sanitize(original)

    #expect(sanitized.contains("{{CLAUDE_DIR}}"))
    #expect(!sanitized.contains(homeDir))

    let restored = PathSubstitution.restore(sanitized)
    #expect(restored == original)
}

@Test func pathSubstitutionClaudeDirTakesPriority() {
    let homeDir = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
    let claudePath = "\(homeDir).claude/plugins/test"
    let sanitized = PathSubstitution.sanitize(claudePath)

    // Should use {{CLAUDE_DIR}} not {{HOME}}.claude
    #expect(sanitized.hasPrefix("{{CLAUDE_DIR}}"))
    #expect(!sanitized.contains("{{HOME}}.claude"))
}

@Test func pathSubstitutionDataRoundTrip() {
    let homeDir = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
    let json = """
    {"hooks":{"command":"\(homeDir).claude/hooks/run.sh"}}
    """
    let original = Data(json.utf8)

    let sanitized = PathSubstitution.sanitizeData(original)
    let sanitizedStr = String(data: sanitized, encoding: .utf8)!
    #expect(sanitizedStr.contains("{{CLAUDE_DIR}}"))

    let restored = PathSubstitution.restoreData(sanitized)
    #expect(restored == original)
}

@Test func pathSubstitutionBinaryDataPassesThrough() {
    let binaryData = Data([0x00, 0xFF, 0x80, 0x7F, 0xFE, 0xFD])
    let result = PathSubstitution.sanitizeData(binaryData)
    // Non-UTF8 data should pass through unchanged
    #expect(result == binaryData)
}

@Test func pathSubstitutionHomePathOnly() {
    let homeDir = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
    let original = "\(homeDir)Documents/test.txt"
    let sanitized = PathSubstitution.sanitize(original)

    #expect(sanitized == "{{HOME}}Documents/test.txt")

    let restored = PathSubstitution.restore(sanitized)
    #expect(restored == original)
}
