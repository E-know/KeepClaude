import Foundation

protocol FileSystemServicing: Sendable {
    func readData(at url: URL) async throws -> Data
    func writeData(_ data: Data, to url: URL) async throws
    func listContents(of directory: URL) async throws -> [URL]
    func listDirectories(in directory: URL) async throws -> [URL]
    func fileExists(at url: URL) -> Bool
    func directoryExists(at url: URL) -> Bool
    func fileSize(at url: URL) throws -> UInt64
    func modificationDate(at url: URL) throws -> Date
    func createDirectory(at url: URL) async throws
    func copyItem(from source: URL, to destination: URL) async throws
    func removeItem(at url: URL) async throws
}
