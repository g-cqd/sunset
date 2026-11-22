import AppKit
package import Foundation
import ImageIO
package import SunsetRuntime
import UniformTypeIdentifiers
import WebKit

/// A tab's frames into a page that asked: 30 a second at most, as JPEG; it stops by the rules of `TabShare.stop`. The
/// page pulls each frame through its message handler (`pull`), and only the origin that asked for the share is given any
/// (no function of Sunset's on the page's window, which its scripts could list and call).
@MainActor
package final class ShareSession {
    /// Where its tasks run, the clock it waits on, the time it reads; `.live` unless a test sets another.
    package var runtime = Runtime.live

    package let source: UUID
    private weak var page: WebContent?
    private let feed: ShareFeed
    private let startHost: String?
    /// The origin (scheme, host, port) of the frame that asked: the only one given frames.
    package let asker: String?
    private var task: Task<Void, Never>?
    /// The newest frame not yet pulled, as Base64; the page's pull waiting for one.
    private var latest: String?
    private var waiter: CheckedContinuation<String?, Never>?
    package private(set) var stopped: TabShare.Stop?

    init(source: UUID, feed: ShareFeed, page: WebContent, asker: String?) {
        self.source = source
        self.feed = feed
        self.page = page
        self.asker = asker
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
    /// The page says its track ended: believed from the origin that asked only (a frame of another site in the page cannot
    /// end the call's share: the outside audit's HIGH-05).
    package func ended(by origin: String?) {
        guard origin != nil, origin == asker else { return }
        stop(.stopped, tellPage: false)
    }

    package func stop(_ why: TabShare.Stop, tellPage: Bool = true) {
        guard stopped == nil else { return }
        stopped = why
        task?.cancel()
        feed.shared(false)
        WebShare.sessions.removeAll { $0 === self }
        // The page's pull is answered with nothing: its track ends (it ended it itself when `tellPage` is false).
        latest = nil
        waiter?.resume(returning: nil)
        waiter = nil
        if page?.capture == .screen { page?.capture = nil }
        page?.share = nil
    }

    private static let interval = Duration.milliseconds(33)

    private func run() async {
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
            guard page?.webView != nil, !Task.isCancelled else { return }
            deliver(encoded.base64EncodedString())
            let spent = runtime.uptime() - start
            if spent < Self.interval { await runtime.sleep(for: Self.interval - spent) }
        }
    }

    /// The next frame for a page's pull from `origin`: the newest not yet pulled, or the next made; nothing once stopped,
    /// or for any origin but the asker's (a frame of another site inside the call's page gets no pixel of the share).
    package func pull(from origin: String?) async -> String? {
        guard stopped == nil, origin != nil, origin == asker else { return nil }
        if let frame = latest {
            latest = nil
            return frame
        }
        waiter?.resume(returning: nil)
        return await withCheckedContinuation { waiter = $0 }
    }

    /// A frame made: to the pull waiting, else kept in the place of one not pulled (none piles up).
    package func deliver(_ frame: String) {
        if let waiting = waiter {
            waiter = nil
            waiting.resume(returning: frame)
        } else {
            latest = frame
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
