import Foundation
import SunsetUpdate

extension UpdateTransfer {
    /// Fetches a single byte range from `url` (verifying `If-Match` / `206`, ADR-0125), reporting streaming progress.
    static func fetchRange(
        url: URL,
        start: Int,
        length: Int,
        expectedETag: String? = nil,
        onProgress: (@Sendable (Int64, Int64) -> Void)? = nil
    ) async throws -> (data: Data, etag: String?, resolvedURL: URL) {
        guard length > 0 else { return (Data(), expectedETag, url) }
        if url.isFileURL {
            guard allowsLocalFeed else { throw Failed(errorDescription: "local update address is not allowed.") }
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            try handle.seek(toOffset: UInt64(start))
            let chunk = try handle.read(upToCount: length) ?? Data()
            onProgress?(Int64(chunk.count), Int64(chunk.count))
            return (chunk, nil, url)
        }
        try enforcePolicy(url)
        var request = URLRequest(url: url)
        request.setValue("bytes=\(start)-\(start + length - 1)", forHTTPHeaderField: "Range")
        if let expectedETag { request.setValue(expectedETag, forHTTPHeaderField: "If-Match") }

        let (data, http) = try await UpdateHTTPTransfer.data(
            for: request,
            allowRedirect: { allowsLocalFeed || UpdateURLPolicy.isAllowed($0) },
            onProgress: onProgress
        )
        guard http.statusCode == 206 else {
            throw Failed(errorDescription: "range request returned HTTP \(http.statusCode).")
        }
        if let finalURL = http.url { try enforcePolicy(finalURL) }
        let etag = http.value(forHTTPHeaderField: "ETag")
        if let expectedETag, let etag, etag != expectedETag {
            throw Failed(errorDescription: "asset changed mid-download.")
        }
        return (data, etag, http.url ?? url)
    }

    static var allowsLocalFeed: Bool {
        ProcessInfo.processInfo.environment["SUNSET_UPDATES_FEED"] != nil
    }

    static func enforcePolicy(_ url: URL) throws {
        guard allowsLocalFeed || UpdateURLPolicy.isAllowed(url) else {
            throw Failed(errorDescription: "refused untrusted update host \(url.host() ?? "unknown").")
        }
    }
}
