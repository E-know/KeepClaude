import Foundation

struct PushDiffItem: Identifiable, Sendable {
    let id = UUID()
    let fileName: String
    let category: SettingsCategory
    let status: DiffStatus
    let sizeInfo: String
}
