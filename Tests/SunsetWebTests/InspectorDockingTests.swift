import AemiTestKit
import AppKit
import SunsetPrivate
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb
@testable import SunsetWebModel

/// "the inspector not being usable at all, it flickers and shows nothing … make it work at all time, in any kind of split
/// tabs, and in detached window modes". Docked, WebKit puts the inspector beside the page in the page's superview
/// (Sunset's `WebViewHostView`) and gives the page what is left; the host set the page back to its whole size at every
/// layout, over the inspector: the two fought (flicker), the inspector under the page (nothing shown).
@MainActor @Suite("The web inspector, docked in a pane", .serialized, .timeLimit(.minutes(1)))
struct InspectorDockingTests {
    private func hosted() async throws -> (NSWindow, WebViewHostView, WebContent) {
        var settings = WebSettings(applicationName: "x")
        settings.developer = true
        let page = WebContent(url: nil, settings: settings)
        page.setState(focused: false, visible: true)
        let view = try #require(page.webView)
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled, .resizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        let host = WebViewHostView(webView: view)
        window.contentView = host
        host.frame = window.contentView?.bounds ?? .zero
        host.place()
        window.makeKeyAndOrderFront(nil)
        view.loadHTMLString("<p>inspect me</p>", baseURL: URL(string: "https://inspect.example/"))
        try await waitForObservedState { !page.isLoading && page.webView?.url?.host() == "inspect.example" }
        return (window, host, page)
    }

    /// The inspector's view: the host's subview that is not the page's.
    private func inspectorView(in host: WebViewHostView) -> NSView? {
        host.subviews.first { $0 !== host.webView }
    }

    @Test func `docked: the inspector is beside the page, both stay put, and a resize keeps them apart`() async throws {
        let (window, host, page) = try await hosted()
        defer {
            page.closeInspector()
            window.close()
            page.stop()
        }
        await page.showInspector(docked: true)
        // WebKit's state, with no event to wait for: looked at until it holds.
        #expect(await RealWait.until { (self.inspectorView(in: host)?.frame.height ?? 0) > 50 })
        let inspector = try #require(inspectorView(in: host), "no inspector beside the page")
        let pageFrame = host.webView.frame
        #expect(inspector.frame.height > 50 && inspector.frame.width > 50, "inspector \(inspector.frame)")
        #expect(!pageFrame.intersects(inspector.frame), "page \(pageFrame) over inspector \(inspector.frame)")
        // Stays put: layouts do not move the page back over it (the flicker).
        for _ in 0 ..< 5 {
            host.needsLayout = true
            host.layoutSubtreeIfNeeded()
        }
        #expect(host.webView.frame == pageFrame, "moved to \(host.webView.frame)")
        // A pane resized (a split dragged): both follow, still apart, filling the pane.
        window.setContentSize(CGSize(width: 700, height: 600))
        host.layoutSubtreeIfNeeded()
        await RealWait.until { abs(host.webView.frame.union(inspector.frame).height - host.bounds.height) < 1.5 }
        #expect(!host.webView.frame.intersects(inspector.frame), "page \(host.webView.frame) over \(inspector.frame)")
        #expect(abs(host.webView.frame.union(inspector.frame).width - host.bounds.width) < 1.5)
        #expect(abs(host.webView.frame.union(inspector.frame).height - host.bounds.height) < 1.5)
    }

    /// A page moved to another pane (a tab shown elsewhere, the split changed, a tab put in its own window): the docked
    /// inspector goes with it, and the pane it left keeps nothing of it.
    @Test func `docked, the page moved to another pane or window takes its inspector along`() async throws {
        let (window, host, page) = try await hosted()
        let other = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        other.isReleasedWhenClosed = false
        defer {
            page.closeInspector()
            window.close()
            other.close()
            page.stop()
        }
        await page.showInspector(docked: true)
        #expect(await RealWait.until { host.isInspectorDocked })
        let moved = WebViewHostView(webView: host.webView)
        other.contentView = moved
        moved.frame = other.contentView?.bounds ?? .zero
        moved.place()
        other.makeKeyAndOrderFront(nil)
        moved.layoutSubtreeIfNeeded()
        await RealWait.until { (moved.subviews.first { $0 !== moved.webView }?.frame.height ?? 0) > 50 }
        #expect(!host.isInspectorDocked && host.subviews.isEmpty, "the old pane keeps \(host.subviews)")
        let inspector = try #require(moved.subviews.first { $0 !== moved.webView }, "no inspector in the new pane")
        #expect(!moved.webView.frame.intersects(inspector.frame) && inspector.frame.height > 50)
        #expect(abs(moved.webView.frame.union(inspector.frame).height - moved.bounds.height) < 1.5)
    }

    @Test func `closed, the page has its whole pane back; detached, the inspector is in a window and the page whole`()
        async throws
    {
        let (window, host, page) = try await hosted()
        defer {
            page.closeInspector()
            window.close()
            page.stop()
        }
        await page.showInspector(docked: true)
        #expect(await RealWait.until { host.isInspectorDocked })
        page.closeInspector()
        #expect(await RealWait.until { !host.isInspectorDocked })
        host.layoutSubtreeIfNeeded()
        #expect(
            host.webView.frame == host.bounds && !host.isInspectorDocked,
            "closed: page \(host.webView.frame) in \(host.bounds), \(host.subviews.map { "\(type(of: $0)) \($0.frame) hidden \($0.isHidden)" })"
        )
        await page.showInspector(docked: false)
        await RealWait.until { NSApp.windows.contains { $0 !== window && $0.isVisible && $0.frame.width > 200 } }
        host.layoutSubtreeIfNeeded()
        #expect(page.isInspectorVisible)
        #expect(host.webView.frame == host.bounds && !host.isInspectorDocked)
        let windows = NSApp.windows.filter { $0 !== window && $0.isVisible && $0.contentView?.frame.width ?? 0 > 200 }
        #expect(
            !windows.isEmpty,
            "no inspector window: \(NSApp.windows.map { "\(type(of: $0)) visible \($0.isVisible) \($0.frame)" })"
        )
    }
}
