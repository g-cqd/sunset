import Foundation
import Synchronization
import Testing

@testable import SunsetUpdate

/// Verifies that `UpdateHTTPTransfer` actually fires streaming progress callbacks on both `data(for:)` and
/// `download(from:to:)` — unlike Swift's `URLSession.data(for:delegate:)` / `download(from:delegate:)` async
/// overloads, which bypass `URLSessionDataDelegate` and `URLSessionDownloadDelegate` progress callbacks on macOS.
@Suite("Update HTTP transfer progress")
struct UpdateHTTPTransferTests {
    private static let body = Data(repeating: 0x5A, count: 64 * 1024)

    /// Minimal `URLProtocol` stub serving a 64 KiB payload in 8 KiB chunks so progress callbacks are deterministic and
    /// require no network access.
    private final class ChunkedStub: URLProtocol, @unchecked Sendable {
        override class func canInit(with request: URLRequest) -> Bool {
            request.url?.scheme == "sunset-stub"
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            guard let url = request.url else { return }
            let headers = ["Content-Length": "\(UpdateHTTPTransferTests.body.count)", "ETag": "\"stub-etag\""]
            guard
                let response = HTTPURLResponse(
                    url: url,
                    statusCode: request.value(forHTTPHeaderField: "Range") != nil ? 206 : 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: headers
                )
            else { return }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            let chunkSize = 8 * 1024
            var offset = 0
            while offset < UpdateHTTPTransferTests.body.count {
                let end = min(offset + chunkSize, UpdateHTTPTransferTests.body.count)
                client?.urlProtocol(self, didLoad: UpdateHTTPTransferTests.body[offset ..< end])
                offset = end
            }
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    private func stubConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ChunkedStub.self]
        return config
    }

    @Test func `data transfer streams progress across chunks and returns full payload`() async throws {
        var request = URLRequest(url: try #require(URL(string: "sunset-stub://updates.test/archive.deltas")))
        request.setValue("bytes=0-\(Self.body.count - 1)", forHTTPHeaderField: "Range")
        let updates = Mutex<[(Int64, Int64)]>([])
        let (data, http) = try await UpdateHTTPTransfer.data(
            for: request,
            configuration: stubConfiguration(),
            allowRedirect: { _ in true },
            onProgress: { received, total in updates.withLock { $0.append((received, total)) } }
        )
        #expect(http.statusCode == 206)
        #expect(data == Self.body)
        let seen = updates.withLock { $0 }
        #expect(!seen.isEmpty, "must report progress during transfer")
        #expect(seen.last?.0 == Int64(Self.body.count))
        #expect(seen.last?.1 == Int64(Self.body.count))
    }

    @Test func `file download streams progress across chunks and writes exact bytes`() async throws {
        let url = try #require(URL(string: "sunset-stub://updates.test/Sunset.zip"))
        let destination = FileManager.default.temporaryDirectory
            .appending(path: "sunset-http-test-\(UUID().uuidString).zip")
        defer { try? FileManager.default.removeItem(at: destination) }
        let updates = Mutex<[(Int64, Int64)]>([])
        let http = try await UpdateHTTPTransfer.download(
            from: url,
            to: destination,
            configuration: stubConfiguration(),
            allowRedirect: { _ in true },
            onProgress: { received, total in updates.withLock { $0.append((received, total)) } }
        )
        #expect(http.statusCode == 200)
        #expect(try Data(contentsOf: destination) == Self.body)
        let seen = updates.withLock { $0 }
        #expect(!seen.isEmpty, "must report progress during download")
        #expect(seen.last?.0 == Int64(Self.body.count))
        #expect(seen.last?.1 == Int64(Self.body.count))
    }
}
