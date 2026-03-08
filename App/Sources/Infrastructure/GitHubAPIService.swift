import Foundation

private struct GitHubErrorResponse: Decodable {
    let message: String
}

struct GitHubAPIService: GitHubAPIServicing {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable & Sendable>(_ endpoint: GitHubEndpoint) async throws -> T {
        let data = try await requestRaw(endpoint)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }

    func requestRaw(_ endpoint: GitHubEndpoint) async throws -> Data {
        let urlRequest = try endpoint.urlRequest()

        #if DEBUG
        NetworkLogger.logRequest(urlRequest)
        let startTime = ContinuousClock.now
        #endif

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            #if DEBUG
            NetworkLogger.logError(error, url: urlRequest.url?.absoluteString)
            #endif
            throw NetworkError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse(statusCode: 0)
        }

        #if DEBUG
        let duration = ContinuousClock.now - startTime
        NetworkLogger.logResponse(httpResponse, data: data, duration: duration)
        #endif

        switch httpResponse.statusCode {
        case 200..<300:
            return data
        case 401:
            throw NetworkError.unauthorized
        case 403:
            let remaining = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Remaining")
            if remaining == "0" {
                let resetTimestamp = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Reset")
                let resetDate = resetTimestamp.flatMap { TimeInterval($0) }.map { Date(timeIntervalSince1970: $0) }
                throw NetworkError.rateLimited(resetDate: resetDate)
            } else {
                let message = (try? JSONDecoder().decode(GitHubErrorResponse.self, from: data))?.message
                    ?? "접근이 거부되었습니다."
                throw NetworkError.forbidden(message)
            }
        case 404:
            throw NetworkError.notFound
        case 422:
            let message = (try? JSONDecoder().decode(GitHubErrorResponse.self, from: data))?.message
                ?? "요청 데이터가 올바르지 않습니다."
            throw NetworkError.validationFailed(message)
        default:
            throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode)
        }
    }
}
