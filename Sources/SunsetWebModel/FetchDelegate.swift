package import Foundation
internal import Synchronization

/// One fetch of `WebFetch`: its body read as it comes, a piece at a time, and dropped past `limit`; a redirect followed only
/// to where the first address could go (`WebFetch.reaches`); and, when the address was checked, the answer kept only if the
/// connection was made to a public address (a name can resolve elsewhere the second time it is looked up).
final class FetchDelegate: NSObject, URLSessionDataDelegate, Sendable {
    private struct State {
        var data = Data()
        var response: URLResponse?
        var remote: String?
        var refused = false
        var done: CheckedContinuation<(data: Data, response: URLResponse)?, Never>?
    }

    private let state = Mutex(State())
    private let limit: Int
    private let page: URL?
    private let proxied: Bool

    init(limit: Int, page: URL?, proxied: Bool) {
        self.limit = limit
        self.page = page
        self.proxied = proxied
    }

    /// Runs `task`, waiting for its end.
    func run(_ task: URLSessionDataTask) async -> (data: Data, response: URLResponse)? {
        await withCheckedContinuation { done in
            state.withLock { $0.done = done }
            task.resume()
        }
    }

    private func refuse(_ task: URLSessionTask) {
        state.withLock { $0.refused = true }
        task.cancel()
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse
    ) async -> URLSession.ResponseDisposition {
        if response.expectedContentLength > Int64(limit) {
            state.withLock { $0.refused = true }
            return .cancel
        }
        state.withLock { $0.response = response }
        return .allow
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let over = state.withLock { state in
            state.data.append(data)
            return state.data.count > limit
        }
        if over { refuse(dataTask) }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest
    ) async -> URLRequest? {
        guard let next = request.url, WebFetch.reaches(next, for: page, proxied: proxied) else {
            refuse(task)
            return nil
        }
        return request
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        let remote = metrics.transactionMetrics.last?.remoteAddress
        state.withLock { $0.remote = remote }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        let (done, result) = state.withLock {
            state -> (
                CheckedContinuation<(data: Data, response: URLResponse)?, Never>?, (data: Data, response: URLResponse)?
            ) in
            defer { state.done = nil }
            guard error == nil, !state.refused, let response = state.response, landed(state.remote, task) else {
                return (state.done, nil)
            }
            return (state.done, (state.data, response))
        }
        done?.resume(returning: result)
    }

    /// Whether the connection went where the address allowed: checked when the address was a page's, without a proxy.
    private func landed(_ remote: String?, _ task: URLSessionTask) -> Bool {
        guard let page, !proxied, let remote, let address = PublicAddress.literal(remote) else { return true }
        let host = task.currentRequest?.url?.host()?.lowercased()
        return PublicAddress.isPublic(address) || host == page.host()?.lowercased()
    }
}
