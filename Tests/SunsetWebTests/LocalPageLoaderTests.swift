import AemiTestKit
import Foundation
import SunsetTestSupport
import Testing
import WebKit

@testable import SunsetWeb

/// An HTML file opened as a document is drawn as a page: it reads the styles of its folder, its text is drawn again as it
/// is edited (unsaved), where it was scrolled to, and a link it follows is Sunset's to open.
@MainActor @Suite("A page document drawn", .serialized, .timeLimit(.minutes(1)))
struct LocalPageLoaderTests {
    private static let style = "body { color: rgb(1, 2, 3); }"
    private static func html(_ title: String, tall: Bool = false) -> String {
        let filler = tall ? String(repeating: "<p>line</p>", count: 400) : ""
        return """
            <html><head><title>\(title)</title><link rel="stylesheet" href="style.css"></head>
            <body><a id="out" href="other.html">other</a>\(filler)</body></html>
            """
    }

    private func folder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: "local-page-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Self.style.write(to: folder.appending(path: "style.css"), atomically: true, encoding: .utf8)
        return folder
    }

    private func value(_ view: WKWebView, _ script: String) async throws -> String {
        try await view.evaluateJavaScript(script) as? String ?? ""
    }

    @Test func `the file reads its folder; edits are drawn unsaved, the scroll kept; a link is handed over`()
        async throws
    {
        let folder = try folder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appending(path: "index.html")
        try Self.html("Saved", tall: true).write(to: file, atomically: true, encoding: .utf8)
        var followed: [URL] = []
        let loader = LocalPageLoader { followed.append($0) }
        let configuration = WKWebViewConfiguration()
        LocalPageLinks.install(in: configuration.userContentController) { [weak loader] in loader?.onLink($0) }
        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 400, height: 300), configuration: configuration)
        view.navigationDelegate = loader
        loader.view = view
        loader.show(.init(text: Self.html("Saved", tall: true), file: file, allowsNetwork: false))
        try await waitUntil(timeout: .seconds(30), label: "drawn") { !view.isLoading && view.title == "Saved" }
        #expect(try await value(view, "getComputedStyle(document.body).color") == "rgb(1, 2, 3)", "its folder's style")
        _ = try await view.evaluateJavaScript("window.scrollTo(0, 500); ''")
        loader.show(.init(text: Self.html("Edited", tall: true), file: file, allowsNetwork: false))
        try await waitUntil(timeout: .seconds(10), label: "edited") { !view.isLoading && view.title == "Edited" }
        try await waitUntil(timeout: .seconds(5), label: "scrolled") {
            (try? await view.evaluateJavaScript("String(window.scrollY)") as? String) == "500"
        }
        #expect(try await value(view, "getComputedStyle(document.body).color") == "rgb(1, 2, 3)", "still its style")
        _ = try await view.evaluateJavaScript("document.getElementById('out').click(); ''")
        try await waitUntil(timeout: .seconds(5), label: "followed") { !followed.isEmpty }
        #expect(followed.first?.lastPathComponent == "other.html" && view.title == "Edited", "Sunset opens it")
        LocalPageLinks.remove(from: configuration.userContentController)
        loader.stop()
    }
}
