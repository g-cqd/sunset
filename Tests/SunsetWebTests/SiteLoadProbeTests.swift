import AppKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb

/// A probe, run when `SUNSET_SITE_PROBE` names an address (roadmap 0045 F; never in the suite: it needs the network): the site
/// loaded by Sunset's own page, shown as `SUNSET_SITE_AGENT` (chrome by default), with the blocking lists of
/// `SUNSET_BLOCKING_LISTS` when given; where it ended, its text, and what its scripts reported, printed.
@MainActor @Suite("A real site loaded by Sunset's page (probe)", .timeLimit(.minutes(2)))
struct SiteLoadProbeTests {
    static let capture = """
        (() => {
          const post = (kind, text) => { try { webkit.messageHandlers.probe.postMessage(kind + ': ' + String(text).slice(0, 400)); } catch (e) {} };
          addEventListener('error', e => post('error', (e.message || e.target?.src || e.target?.href || e) + ' @' + (e.filename || '') + ':' + (e.lineno || '')), true);
          addEventListener('unhandledrejection', e => post('rejection', e.reason && (e.reason.stack || e.reason.message) || e.reason));
          addEventListener('securitypolicyviolation', e => post('csp', e.violatedDirective + ' ' + e.blockedURI));
          for (const level of ['error', 'warn']) {
            const original = console[level];
            console[level] = (...args) => { post('console.' + level, args.map(a => { try { return typeof a === 'string' ? a : JSON.stringify(a); } catch (e) { return String(a); } }).join(' ')); original.apply(console, args); };
          }
        })();
        """

    final class Lines: NSObject, WKScriptMessageHandler {
        var lines: [String] = []
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            lines.append("\(message.body)")
        }
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["SUNSET_SITE_PROBE"] != nil))
    func `a real site, as Sunset loads it`() async throws {
        let environment = ProcessInfo.processInfo.environment
        let address = try #require(environment["SUNSET_SITE_PROBE"].flatMap(URL.init(string:)))
        let lists = environment["SUNSET_BLOCKING_LISTS"]?.split(separator: ":") ?? []
        if !lists.isEmpty {
            let sources = try lists.map {
                ContentBlocker.Source(
                    address: "https://lists.example/\($0)",
                    text: try String(contentsOfFile: String($0), encoding: .utf8),
                    updated: .now
                )
            }
            await ContentBlocker.shared.load(sources)
            print("probe: blocking", ContentBlocker.shared.states.map(\.rules))
        }
        var settings = WebSettings(applicationName: "Version/26.0 Safari/605.1.15")
        settings.agent = environment["SUNSET_SITE_AGENT"].flatMap(BrowserAgent.init(rawValue:)) ?? .chrome
        settings.privacy = PagePrivacy()
        let page = WebContent(url: nil, settings: settings)
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        defer { window.close() }
        page.setState(focused: true, visible: true)
        let view = try #require(page.webView)
        window.contentView = view
        window.orderBack(nil)
        let lines = Lines()
        view.configuration.userContentController.add(lines, name: "probe")
        view.configuration.userContentController.addUserScript(
            WKUserScript(source: Self.capture, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        )
        page.load(address)
        let seconds = Double(environment["SUNSET_SITE_WAIT"] ?? "") ?? 15
        await RealWait.pass(.seconds(seconds))
        // Then shown another browser from the site's panel, as the person would.
        if let then = environment["SUNSET_SITE_THEN_AGENT"].flatMap(BrowserAgent.init(rawValue:)) {
            print("probe: first at", page.url?.absoluteString ?? "-")
            page.agents = SiteAgents()
            page.appear(as: then)
            await RealWait.pass(.seconds(seconds))
        }
        let state = try await view.evaluateJavaScript(
            "JSON.stringify({href: location.href, title: document.title, ua: navigator.userAgent, text: (document.body ? document.body.innerText : '').slice(0, 300)})"
        )
        print("probe: state", state ?? "nil", "loading", page.isLoading, "progress", page.progress ?? -1)
        // A page that writes what it reads of the browser into #out (the fingerprint page of diary 2026-11-18-03).
        if let out = try await view.evaluateJavaScript("document.getElementById('out')?.textContent ?? ''") as? String,
            !out.isEmpty
        {
            try out.write(toFile: "/tmp/sunset-site-probe.json", atomically: true, encoding: .utf8)
        }
        print("probe: failure", String(describing: page.failure))
        for line in lines.lines { print("probe:  ", line) }
        if let image = try? await view.takeSnapshot(configuration: nil), let tiff = image.tiffRepresentation,
            let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
        {
            try png.write(to: URL(fileURLWithPath: "/tmp/sunset-site-probe.png"))
        }
    }
}
