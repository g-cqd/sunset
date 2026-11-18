package import Foundation
import Network

/// Whether pages go through the proxy (the owner's note n37): a request made the way pages are (`WebProxy`'s configuration
/// in an ephemeral session) to the page macOS itself asks to find a captive network, and its metrics read. Nothing is sent
/// to anyone but that page, through the proxy; no address of the person is looked up.
package enum ProxyCheck {
    /// What the check found.
    package enum Outcome: Equatable, Sendable {
        /// The request went through the proxy and was answered.
        case throughProxy
        /// It was answered, but not through the proxy: pages would not go through it either.
        case notThroughProxy
        /// The proxy did not answer, or refused (its reason).
        case failed(String)
        /// No proxy is set, or it is not one Sunset reads.
        case noProxy
    }

    /// The page asked (Apple's captive-network check).
    package static let probe: URL = {
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = "captive.apple.com"
        parts.path = "/hotspot-detect.html"
        return parts.url ?? URL(filePath: "/")
    }()

    /// What a finished request means: its status, its error, whether its connection was the proxy's.
    package static func outcome(status: Int?, error: (any Error)?, viaProxy: Bool) -> Outcome {
        if let error {
            let code = (error as? URLError)?.code
            switch code {
                case .cannotConnectToHost, .cannotFindHost, .timedOut, .networkConnectionLost:
                    return .failed("The proxy did not answer.")
                default:
                    return .failed(error.localizedDescription)
            }
        }
        guard let status else { return .failed("No answer.") }
        if status == 407 { return .failed("The proxy asks for a password (407).") }
        guard (200 ..< 400).contains(status) else { return .failed("The proxy answered \(status).") }
        return viaProxy ? .throughProxy : .notThroughProxy
    }

    /// Runs the check through `proxy`: a request as pages make it, its metrics read.
    package static func run(_ proxy: WebProxy?) async -> Outcome {
        guard let proxy else { return .noProxy }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.proxyConfigurations = [proxy.configuration]
        configuration.timeoutIntervalForRequest = 10
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let watcher = MetricsWatcher()
        let session = URLSession(configuration: configuration, delegate: watcher, delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        do {
            let (_, response) = try await session.data(from: probe)
            return outcome(status: (response as? HTTPURLResponse)?.statusCode, error: nil, viaProxy: watcher.viaProxy)
        } catch {
            return outcome(status: nil, error: error, viaProxy: false)
        }
    }

    /// Whether the request's connection was the proxy's (its transaction metrics).
    private final class MetricsWatcher: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
        private let lock = NSLock()
        private var proxied = false
        var viaProxy: Bool { lock.withLock { proxied } }

        func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics)
        {
            let any = metrics.transactionMetrics.contains { $0.isProxyConnection }
            lock.withLock { proxied = proxied || any }
        }
    }
}
