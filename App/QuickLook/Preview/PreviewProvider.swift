import Foundation
import QuickLookUI
import SunsetQuickLookKit
import UniformTypeIdentifiers

/// Sunset's Quick Look preview extension for Markdown and Mermaid files: renders HTML via `MarkdownLookKit` using the
/// preferences domain Sunset writes (`studio.aemi.sunset.quicklook`). No network, no JavaScript.
final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    /// The largest file read whole; beyond it the preview shows the start.
    private static let limit = 8 << 20
    private static let preferencesDomain = "studio.aemi.sunset.quicklook"

    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let handle = try FileHandle(forReadingFrom: request.fileURL)
        defer { try? handle.close() }
        let bytes = Array(try handle.read(upToCount: Self.limit) ?? Data())
        let title = request.fileURL.lastPathComponent
        let name = title.lowercased()
        let isDiagram = name.hasSuffix(".mmd") || name.hasSuffix(".mermaid")
        var renderer = MarkdownHTMLRenderer()
        renderer.settings = ViewerSettings.current(domain: Self.preferencesDomain)
        let page = isDiagram ? renderer.diagramPage(bytes, title: title) : renderer.page(markdown: bytes, title: title)
        let reply = QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 800, height: 800)) { reply in
            reply.stringEncoding = .utf8
            return Data(page.utf8)
        }
        reply.title = title
        return reply
    }
}
