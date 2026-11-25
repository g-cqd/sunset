public import Foundation
internal import Synchronization

/// Ephemeral HTTP transfer helpers for updates (`data` for byte-range fetches, `download` for full archives) that use
/// delegate-driven `URLSession` tasks so redirect validation and incremental byte progress actually fire. Swift's
/// `URLSession.data(for:delegate:)` and `download(from:delegate:)` async overloads bypass `URLSessionDataDelegate` and
/// `URLSessionDownloadDelegate` progress callbacks on macOS, leaving update progress bars frozen at 0%.
public enum UpdateHTTPTransfer {
    public typealias RedirectPolicy = @Sendable (URL) -> Bool
    public typealias ProgressHandler = @Sendable (Int64, Int64) -> Void

    /// Fetches `request` into memory while enforcing `allowRedirect` on every redirect and streaming `(received, total)`
    /// to `onProgress`.
    public static func data(
        for request: URLRequest,
        configuration: URLSessionConfiguration = .ephemeral,
        allowRedirect: @escaping RedirectPolicy,
        onProgress: ProgressHandler? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        let runner = Runner(destination: nil, allowRedirect: allowRedirect, onProgress: onProgress)
        return try await runner.run(configuration: configuration) { $0.dataTask(with: request) }
    }

    /// Downloads `url` to `destination` while enforcing `allowRedirect` on every redirect and streaming
    /// `(totalBytesWritten, totalBytesExpected)` to `onProgress`.
    public static func download(
        from url: URL,
        to destination: URL,
        configuration: URLSessionConfiguration = .ephemeral,
        allowRedirect: @escaping RedirectPolicy,
        onProgress: ProgressHandler? = nil
    ) async throws -> HTTPURLResponse {
        let runner = Runner(destination: destination, allowRedirect: allowRedirect, onProgress: onProgress)
        let (_, response) = try await runner.run(configuration: configuration) { $0.downloadTask(with: url) }
        return response
    }

    /// Single `URLSession` delegate handling both in-memory range data tasks (`destination == nil`) and on-disk
    /// download tasks (`destination != nil`) with redirect filtering and incremental progress callbacks.
    private final class Runner: NSObject, URLSessionDataDelegate, URLSessionDownloadDelegate, @unchecked Sendable {
        private let destination: URL?
        private let allowRedirect: RedirectPolicy
        private let onProgress: ProgressHandler?
        private var expectedTotal: Int64 = 0
        private var buffer = Data()
        private var response: HTTPURLResponse?
        private var moveError: (any Error)?
        private var moved = false
        private let continuation = Mutex<CheckedContinuation<(Data, HTTPURLResponse), any Error>?>(nil)

        init(destination: URL?, allowRedirect: @escaping RedirectPolicy, onProgress: ProgressHandler?) {
            self.destination = destination
            self.allowRedirect = allowRedirect
            self.onProgress = onProgress
        }

        func run(
            configuration: URLSessionConfiguration,
            makeTask: (URLSession) -> URLSessionTask
        ) async throws -> (Data, HTTPURLResponse) {
            let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
            defer { session.finishTasksAndInvalidate() }
            let task = makeTask(session)
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { cont in
                    continuation.withLock { $0 = cont }
                    task.resume()
                }
            } onCancel: {
                task.cancel()
            }
        }

        func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            willPerformHTTPRedirection response: HTTPURLResponse,
            newRequest request: URLRequest,
            completionHandler: @escaping (URLRequest?) -> Void
        ) {
            guard let target = request.url, allowRedirect(target) else {
                completionHandler(nil)
                return
            }
            completionHandler(request)
        }

        func urlSession(
            _ session: URLSession,
            dataTask: URLSessionDataTask,
            didReceive response: URLResponse,
            completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
        ) {
            self.response = response as? HTTPURLResponse
            expectedTotal = max(response.expectedContentLength, 0)
            if expectedTotal > 0 { buffer.reserveCapacity(Int(min(expectedTotal, 64 * 1024 * 1024))) }
            completionHandler(.allow)
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            buffer.append(data)
            onProgress?(Int64(buffer.count), expectedTotal)
        }

        func urlSession(
            _ session: URLSession,
            downloadTask: URLSessionDownloadTask,
            didWriteData bytesWritten: Int64,
            totalBytesWritten: Int64,
            totalBytesExpectedToWrite: Int64
        ) {
            onProgress?(totalBytesWritten, max(totalBytesExpectedToWrite, 0))
        }

        func urlSession(
            _ session: URLSession,
            downloadTask: URLSessionDownloadTask,
            didFinishDownloadingTo location: URL
        ) {
            response = downloadTask.response as? HTTPURLResponse
            guard let destination else { return }
            do {
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.moveItem(at: location, to: destination)
                moved = true
            } catch {
                moveError = error
            }
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
            guard
                let cont = continuation.withLock({ value in
                    let taken = value
                    value = nil
                    return taken
                })
            else { return }
            if let error {
                cont.resume(throwing: error)
            } else if let moveError {
                cont.resume(throwing: moveError)
            } else if let response, destination == nil || moved {
                cont.resume(returning: (buffer, response))
            } else {
                cont.resume(throwing: URLError(.badServerResponse))
            }
        }
    }
}
