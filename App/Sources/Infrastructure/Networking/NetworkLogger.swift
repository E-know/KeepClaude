#if DEBUG
import Foundation
import os

enum NetworkLogger {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "KeepClaude",
        category: "Network"
    )

    static func logRequest(_ request: URLRequest) {
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "nil"
        let headers = request.allHTTPHeaderFields?
            .filter { $0.key != "Authorization" }
            .map { "  \($0.key): \($0.value)" }
            .joined(separator: "\n") ?? "  (none)"
        let body = request.httpBody
            .flatMap { String(data: $0, encoding: .utf8) }
            .map { prettyJSON($0) } ?? "(empty)"

        logger.debug("""
        ➡️ REQUEST \(method) \(url)
        Headers:
        \(headers)
        Body: \(body)
        """)
    }

    static func logResponse(_ response: HTTPURLResponse, data: Data, duration: Duration) {
        let status = response.statusCode
        let url = response.url?.absoluteString ?? "nil"
        let size = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .memory)
        let body = String(data: data, encoding: .utf8)
            .map { prettyJSON($0) } ?? "(binary \(size))"

        let icon = (200..<300).contains(status) ? "✅" : "❌"
        logger.debug("""
        \(icon) RESPONSE \(status) \(url) (\(duration)) [\(size)]
        Body: \(body)
        """)
    }

    static func logError(_ error: Error, url: String?) {
        logger.error("⚠️ NETWORK ERROR \(url ?? "nil"): \(error.localizedDescription)")
    }

    private static func prettyJSON(_ string: String) -> String {
        guard let data = string.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
              let result = String(data: pretty, encoding: .utf8) else {
            return string
        }
        return result
    }
}
#endif
