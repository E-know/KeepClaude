import Foundation

enum NetworkError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case unauthorized
    case forbidden(String)
    case rateLimited(resetDate: Date?)
    case notFound
    case validationFailed(String)
    case decodingError(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            String(localized: "잘못된 URL입니다.")
        case .invalidResponse(let statusCode):
            String(localized: "서버 응답 오류입니다. (HTTP \(statusCode))")
        case .unauthorized:
            String(localized: "인증이 필요합니다. GitHub Personal Access Token을 확인해주세요.")
        case .forbidden(let message):
            String(localized: "접근 권한이 없습니다. GitHub Token의 권한(scope)을 확인해주세요. (\(message))")
        case .rateLimited(let resetDate):
            if let resetDate {
                String(localized: "GitHub API 요청 한도를 초과했습니다. \(resetDate.formatted(date: .omitted, time: .shortened))에 초기화됩니다.")
            } else {
                String(localized: "GitHub API 요청 한도를 초과했습니다. 잠시 후 다시 시도해주세요.")
            }
        case .notFound:
            String(localized: "요청한 리소스를 찾을 수 없습니다.")
        case .validationFailed(let message):
            String(localized: "요청이 거부되었습니다: \(message)")
        case .decodingError(let message):
            String(localized: "응답 데이터 파싱 오류: \(message)")
        case .networkError(let message):
            String(localized: "네트워크 오류: \(message)")
        }
    }
}
