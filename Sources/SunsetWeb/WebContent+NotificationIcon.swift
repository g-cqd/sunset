package import Foundation
import WebKit

/// The picture of a page's notification: fetched as the page's icon is (without cookies, as the browser the site is
/// shown), at most 1 MB, made a PNG of 256 px at most, written to a file of its own for the notification centre.
extension WebContent {
    /// The most read of a notification's picture.
    static let notificationIconLimit = 1 << 20

    /// A file holding the notification's picture, made small; nil when it has none, or it could not be had.
    package func notificationIcon(for note: WebNotification) async -> URL? {
        guard let address = note.icon, !isPrivate || address.scheme == "data" else { return nil }
        let agent = try? await webView?.evaluateJavaScript("navigator.userAgent") as? String
        guard let agent, !agent.isEmpty,
            let (data, _) = await WebFetch.data(
                address,
                agent: agent,
                limit: Self.notificationIconLimit,
                for: url,
                proxy: settings.proxy ?? WebProxy.current
            ),
            let png = FaviconStore.small(data, side: 256)
        else { return nil }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(
            "sunset-notification-\(UUID().uuidString).png"
        )
        guard (try? png.write(to: file)) != nil else { return nil }
        return file
    }
}
