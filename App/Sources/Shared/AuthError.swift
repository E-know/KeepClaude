import Foundation

enum AuthError: LocalizedError, Sendable {
    case notAuthenticated
    case invalidToken
    case tokenExpired

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            "GitHub에 연결되어 있지 않습니다. 설정에서 Personal Access Token을 입력해주세요."
        case .invalidToken:
            "유효하지 않은 토큰입니다. 토큰을 다시 확인해주세요."
        case .tokenExpired:
            "토큰이 만료되었습니다. 새 토큰을 발급받아주세요."
        }
    }
}
