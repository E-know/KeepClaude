import Foundation

enum Constants {
    static let claudeDirectoryName = ".claude"
    static let keychainServiceName = "com.inhochoi.KeepClaude"
    static let keychainAccountName = "github-pat"
    static let defaultRepoName = "claude-settings"
    static let githubAPIBaseURL = "https://api.github.com"
    static let manifestFileName = "manifest.json"
    static let manifestVersion = "1.0"
    static let appVersion = "1.0.0"
    static let appleLanguagesKey = "AppleLanguages"

    static var claudeDirectoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appending(path: claudeDirectoryName)
    }

    enum SyncTargets {
        static let settingsJSON = "settings.json"
        static let settingsLocalJSON = "settings.local.json"
        static let keybindingsJSON = "keybindings.json"
        static let pluginsDir = "plugins"
        static let skillsDir = "skills"
        static let commandsDir = "commands"
        static let soundDir = "sound"

        static let pluginFiles = [
            "installed_plugins.json",
            "known_marketplaces.json",
            "config.json",
            "blocklist.json"
        ]
    }

    enum ExcludedPaths {
        static let all: Set<String> = [
            "history.jsonl", "projects", "debug", "cache",
            "telemetry", "todos", "tasks", "teams",
            "file-history", "shell-snapshots", "session-env",
            "stats-cache.json", "mcp-needs-auth-cache.json",
            ".DS_Store", "paste-cache", "plans", "backups",
            "plugins/cache", "plugins/marketplaces",
            "plugins/install-counts-cache.json",
            "plugins/repos", "statsig"
        ]
    }
}
