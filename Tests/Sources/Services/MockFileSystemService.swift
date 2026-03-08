import Foundation
@testable import KeepClaude

final class MockFileSystemService: FileSystemServicing, @unchecked Sendable {
    var files: [String: Data] = [:]
    var directories: Set<String> = []

    func readData(at url: URL) async throws -> Data {
        guard let data = files[url.path(percentEncoded: false)] else {
            throw NSError(domain: "MockFS", code: 1, userInfo: [NSLocalizedDescriptionKey: "File not found: \(url.path())"])
        }
        return data
    }

    func writeData(_ data: Data, to url: URL) async throws {
        let path = url.path(percentEncoded: false)
        files[path] = data
        // Auto-create parent directories
        let parent = url.deletingLastPathComponent().path(percentEncoded: false)
        directories.insert(parent)
    }

    func listContents(of directory: URL) async throws -> [URL] {
        let dirPath = directory.path(percentEncoded: false)
        return files.keys
            .filter { $0.hasPrefix(dirPath) && !$0.dropFirst(dirPath.count).dropFirst().contains("/") }
            .sorted()
            .map { URL(filePath: $0) }
    }

    func listDirectories(in directory: URL) async throws -> [URL] {
        let dirPath = directory.path(percentEncoded: false)
        return directories
            .filter { $0.hasPrefix(dirPath) && $0 != dirPath }
            .sorted()
            .map { URL(filePath: $0) }
    }

    func fileExists(at url: URL) -> Bool {
        files[url.path(percentEncoded: false)] != nil
    }

    func directoryExists(at url: URL) -> Bool {
        directories.contains(url.path(percentEncoded: false))
    }

    func fileSize(at url: URL) throws -> UInt64 {
        UInt64(files[url.path(percentEncoded: false)]?.count ?? 0)
    }

    func modificationDate(at url: URL) throws -> Date {
        Date()
    }

    func createDirectory(at url: URL) async throws {
        directories.insert(url.path(percentEncoded: false))
    }

    func copyItem(from source: URL, to destination: URL) async throws {
        let srcPath = source.path(percentEncoded: false)
        guard let data = files[srcPath] else {
            throw NSError(domain: "MockFS", code: 2, userInfo: nil)
        }
        files[destination.path(percentEncoded: false)] = data
        let parent = destination.deletingLastPathComponent().path(percentEncoded: false)
        directories.insert(parent)
    }

    func removeItem(at url: URL) async throws {
        files.removeValue(forKey: url.path(percentEncoded: false))
    }
}
