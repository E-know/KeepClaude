import Foundation

struct FileSystemService: FileSystemServicing, @unchecked Sendable {
    private let fileManager = FileManager.default

    func readData(at url: URL) async throws -> Data {
        try Data(contentsOf: url)
    }

    func writeData(_ data: Data, to url: URL) async throws {
        let directory = url.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path(percentEncoded: false)) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try data.write(to: url, options: .atomic)
    }

    func listContents(of directory: URL) async throws -> [URL] {
        try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
    }

    func listDirectories(in directory: URL) async throws -> [URL] {
        let contents = try await listContents(of: directory)
        return contents.filter { url in
            var isDir: ObjCBool = false
            return fileManager.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDir) && isDir.boolValue
        }
    }

    func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path(percentEncoded: false))
    }

    func directoryExists(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        return fileManager.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDir) && isDir.boolValue
    }

    func fileSize(at url: URL) throws -> UInt64 {
        let attributes = try fileManager.attributesOfItem(atPath: url.path(percentEncoded: false))
        return attributes[.size] as? UInt64 ?? 0
    }

    func modificationDate(at url: URL) throws -> Date {
        let attributes = try fileManager.attributesOfItem(atPath: url.path(percentEncoded: false))
        return attributes[.modificationDate] as? Date ?? .distantPast
    }

    func createDirectory(at url: URL) async throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func copyItem(from source: URL, to destination: URL) async throws {
        let destDir = destination.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: destDir.path(percentEncoded: false)) {
            try fileManager.createDirectory(at: destDir, withIntermediateDirectories: true)
        }
        try fileManager.copyItem(at: source, to: destination)
    }

    func removeItem(at url: URL) async throws {
        try fileManager.removeItem(at: url)
    }
}
