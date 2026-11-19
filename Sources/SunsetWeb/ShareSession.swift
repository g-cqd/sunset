import AppKit
package import Foundation
import ImageIO
package import SunsetRuntime
import UniformTypeIdentifiers
import WebKit

/// A tab's frames into a page that asked (ADR-0082): pipelined, 30 a second at most, as JPEG; it stops by the rules of
/// `TabShare.stop`.
@MainActor
package final class ShareSession {
    /// Where its tasks run, the clock it waits on, the time it reads (ADR-0087); `.live` unless a test sets another.
    package var runtime = Runtime.live

    package let source: UUID
    private weak var page: WebContent?
    private let feed: ShareFeed
    private let startHost: String?
    private let frameFunction: String
    private let endFunction: String
    private var task: Task<Void, Never>?
    package private(set) var stopped: TabShare.Stop?

    init(source: UUID, feed: ShareFeed, page: WebContent, frameFunction: String, endFunction: String) {
        self.source = source
        self.feed = feed
        self.page = page
        self.frameFunction = frameFunction
        self.endFunction = endFunction
        startHost = feed.host()
    }

    /// Whether `page` is the tab this session shares.
    package func shares(_ page: WebContent) -> Bool {
        feed.page() === page
    }

    func start() {
        WebShare.sessions.append(self)
        feed.shared(true)
        task = runtime.task { @MainActor [weak self] in await self?.run() }
    }

    /// Stops the share; the page's track ends unless it ended it itself.
    package func stop(_ why: TabShare.Stop, tellPage: Bool = true) {
        guard stopped == nil else { return }
        stopped = why
        task?.cancel()
        feed.shared(false)
        WebShare.sessions.removeAll { $0 === self }
        if tellPage, let view = page?.webView {
            view.evaluateJavaScript("window[\"\(endFunction)\"] && window[\"\(endFunction)\"]()", in: nil, in: .page)
        }
        if page?.capture == .screen { page?.capture = nil }
        page?.share = nil
    }

    private static let interval = Duration.milliseconds(33)

    private func run() async {
        var delivery: Task<Void, Never>?
        while !Task.isCancelled {
            let start = runtime.uptime()
            if let why = TabShare.stop(
                sourceOpen: feed.isOpen(),
                requesterOpen: page?.webView != nil,
                startHost: startHost,
                hostNow: feed.host(),
                stoppedByPerson: false
            ) {
                stop(why)
                return
            }
            guard let image = await feed.frame() else {
                await runtime.sleep(for: Self.interval)
                continue
            }
            let encoded = await runtime.detached(priority: .userInitiated) { Self.jpeg(image) }.value
            await delivery?.value
            guard let view = page?.webView, !Task.isCancelled else { return }
            let function = frameFunction
            delivery = runtime.task { @MainActor in
                _ = try? await view.callAsyncJavaScript(
                    "return await window[f](b)",
                    arguments: ["f": function, "b": encoded.base64EncodedString()],
                    contentWorld: .page
                )
            }
            let spent = runtime.uptime() - start
            if spent < Self.interval { await runtime.sleep(for: Self.interval - spent) }
        }
    }

    nonisolated static func jpeg(_ image: CGImage, quality: Double = 0.6) -> Data {
        let out = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(out, UTType.jpeg.identifier as CFString, 1, nil) else {
            return Data()
        }
        CGImageDestinationAddImage(
            destination,
            image,
            [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        )
        CGImageDestinationFinalize(destination)
        return out as Data
    }
}
