import AppKit
import Foundation
import SunsetDocuments
import SunsetPane
import Testing

@testable import SunsetMarkdown

/// "the preview of document and rendered documents does not work", then "there's nesting of the preview in previews". A
/// document's picture is drawn from the document itself, rendered or as source, never from the window: nothing over it
/// is pictured.
@MainActor
@Suite("A document's picture")
struct DocumentPictureTests {
    private func pane(_ view: String) throws -> (DocumentContent, String) {
        let root = NSTemporaryDirectory() + "picture-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: root, withIntermediateDirectories: true)
        try "# Title\n\nSome words here.\n".write(toFile: root + "/n.md", atomically: true, encoding: .utf8)
        let pane = try #require(
            DocumentContent(
                PaneDescriptor(kind: DocumentContent.kind, state: ["file": root + "/n.md", "view": view]),
                documents: OpenDocuments(store: nil)
            )
        )
        return (pane, root)
    }

    /// How many of the picture's pixels differ from its top-left corner (its backdrop).
    private func drawn(_ image: CGImage) -> Int {
        let rep = NSBitmapImageRep(cgImage: image)
        guard let corner = rep.colorAt(x: 0, y: 0) else { return 0 }
        var count = 0
        for y in stride(from: 0, to: rep.pixelsHigh, by: 2) {
            for x in stride(from: 0, to: rep.pixelsWide, by: 2) where rep.colorAt(x: x, y: y) != corner { count += 1 }
        }
        return count
    }

    @Test(arguments: ["rendered", "source"])
    func `a document drawn once is pictured with its text, at the size it was drawn, without a window`(view: String)
        throws
    {
        let (pane, root) = try pane(view)
        defer {
            pane.stop()
            try? FileManager.default.removeItem(atPath: root)
        }
        pane.takePicture()
        #expect(pane.picture == nil, "never drawn: no size to picture it at")
        // Shown once, as in a window: its page is made (only while a pane shows it).
        pane.setState(focused: false, visible: true)
        pane.drawnSize = CGSize(width: 300, height: 200)
        pane.takePicture()
        let image = try #require(pane.picture)
        #expect(image.width >= 300 && image.height >= 200)
        #expect(drawn(image) > 50, "its text is in it")
    }
}
