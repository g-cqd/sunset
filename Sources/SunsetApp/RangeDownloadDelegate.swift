import Foundation
import SunsetUpdate

/// Enforces `UpdateURLPolicy` on every HTTP redirect and reports streaming download progress for both range and full
/// update fetches (ADR-0125).
final class RangeDownloadDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate, @unchecked Sendable {
    private let onProgress: (@Sendable (Int64, Int64) -> Void)?
    private var expectedTotal: Int64 = 0
    private var received: Int64 = 0

    init(onProgress: (@Sendable (Int64, Int64) -> Void)?) {
        self.onProgress = onProgress
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest
    ) async -> URLRequest? {
        guard let destination = request.url,
            UpdateTransfer.allowsLocalFeed || UpdateURLPolicy.isAllowed(destination)
        else { return nil }
        return request
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition {
        expectedTotal = max(response.expectedContentLength, 0)
        return .allow
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        received += Int64(data.count)
        onProgress?(received, expectedTotal)
    }
}
