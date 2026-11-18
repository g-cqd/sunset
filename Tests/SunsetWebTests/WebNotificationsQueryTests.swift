import AppKit
import Foundation
import Observation
import Testing
import WebKit

@testable import SunsetWeb

/// Roadmap 0045 B (the owner, 2026-11-18: "No notifications at all are requested even though some tabs might be emitting
/// some"): a site that asks the Permissions API before it asks or notifies was answered by WebKit, which has no notifications
/// in an app, whatever the site's answer in Sunset.
@MainActor
@Suite("A page's notification permission, as the Permissions API reads it", .timeLimit(.minutes(1)))
struct WebNotificationsQueryTests {
    /// What `navigator.permissions.query` says of notifications on a page of chat.example given `answer`.
    private func state(_ answer: PermissionAnswer?) async throws -> [String] {
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.privacy = PagePrivacy()
        let page = WebContent(url: nil, settings: settings)
        if let answer { page.permissions.set(answer, .notifications, for: "chat.example") }
        page.setState(focused: false, visible: true)
        let view = try #require(page.webView)
        view.loadHTMLString("<p>chat</p>", baseURL: URL(string: "https://chat.example/"))
        while page.isLoading || page.webView?.url?.host() != "chat.example" {
            await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
                withObservationTracking {
                    _ = page.isLoading
                    _ = page.url
                } onChange: {
                    done.resume()
                }
            }
        }
        let result = try await view.callAsyncJavaScript(
            """
            const status = await navigator.permissions.query({ name: 'notifications' });
            return [status.state, status.name, Notification.permission];
            """,
            contentWorld: .page
        )
        page.stop()
        return result as? [String] ?? []
    }

    @Test func `the Permissions API reads the site's answer, as Notification.permission does`() async throws {
        let allowed = try await state(.allow)
        let denied = try await state(.deny)
        let unanswered = try await state(nil)
        #expect(allowed == ["granted", "notifications", "granted"])
        #expect(denied == ["denied", "notifications", "denied"])
        #expect(unanswered == ["prompt", "notifications", "default"])
    }
}
