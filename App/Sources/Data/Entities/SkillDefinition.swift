import Foundation

struct SkillDefinition: Codable, Sendable, Equatable, Identifiable {
    var id: String { name }
    let name: String
    let content: String
}
