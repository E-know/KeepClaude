import Foundation

struct SoundFile: Codable, Sendable, Equatable, Identifiable {
    var id: String { name }
    let name: String
    let data: Data
    let size: UInt64
}
