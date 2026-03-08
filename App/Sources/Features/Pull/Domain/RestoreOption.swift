import Foundation

struct RestoreOption: Identifiable, Sendable {
    let category: SettingsCategory
    var isSelected: Bool
    let existsLocally: Bool

    var id: String { category.rawValue }
}
