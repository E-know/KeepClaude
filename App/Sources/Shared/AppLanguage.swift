import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case ko = "ko"
    case en = "en"
    case ja = "ja"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: String(localized: "시스템 기본값")
        case .ko: "한국어"
        case .en: "English"
        case .ja: "日本語"
        }
    }
}
