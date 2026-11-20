import AppKit
import Foundation
import MarkdownLookKit
import SunsetDocuments
import SunsetPane
import SunsetShell
import SunsetTestSupport
import SwiftUI
import Testing
import UniformTypeIdentifiers

@testable import SunsetMarkdown

/// Pictures of the document pane, drawn in a window that is never shown (the pane as the app makes it, in a hosting view),
/// for looking at when the screen cannot be read. Off unless `SUNSET_CATALOG` names a folder:
/// `SUNSET_CATALOG=/tmp/catalog swift test --filter DocumentPaneCatalog`.
@MainActor
@Suite("The document pane, drawn", .enabled(if: ProcessInfo.processInfo.environment["SUNSET_CATALOG"] != nil))
struct DocumentPaneCatalogTests {
    static let sample = """
        # Tides of the North Sea

        The harbour at low tide is *quiet*; the **boats** lean on the mud, as [the almanac](https://example.org/almanac)
        says, and as [the other note](other.md) has it.

        ![The harbour](harbour.png)

        - a first point, with `code` in it
        - a second one
          1. nested, numbered
          2. and again
        - [x] done
        - [ ] to do

        > [!NOTE]
        > A note in an alert.

        | Port | High | Low |
        | --- | ---: | ---: |
        | Dover | 11:02 | 17:40 |
        | Calais | 11:31 | 18:05 |

        ```swift
        let tide = Tide(port: "Dover", at: .now)
        print(tide.height)
        ```

        ```mermaid
        flowchart LR
          Sea --> Harbour --> Quay
        ```
        """

    private func picture(at path: String) throws {
        let space = CGColorSpaceCreateDeviceRGB()
        let info = CGImageAlphaInfo.premultipliedLast.rawValue
        let context = try #require(
            CGContext(
                data: nil,
                width: 480,
                height: 160,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: space,
                bitmapInfo: info
            )
        )
        let colors = [
            CGColor(red: 1, green: 0.55, blue: 0.2, alpha: 1), CGColor(red: 0.2, green: 0.25, blue: 0.6, alpha: 1)
        ]
        let gradient = try #require(CGGradient(colorsSpace: space, colors: colors as CFArray, locations: [0, 1]))
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: 160), options: [])
        let image = try #require(context.makeImage())
        let url = URL(fileURLWithPath: path) as CFURL
        let destination = try #require(CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
    }

    /// Draws `view` in a window that is not on screen and writes it as a PNG, after `ready` holds or two seconds.
    private func draw(_ view: AnyView, size: CGSize, to path: String, ready: () -> Bool = { true }) async throws {
        let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
        host.frame = CGRect(origin: .zero, size: size)
        let window = NSWindow(
            contentRect: CGRect(x: -20_000, y: -20_000, width: size.width, height: size.height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = host
        window.orderBack(nil)
        try? await Poll.until(within: .seconds(2), every: .milliseconds(50)) { ready() }
        // The window server draws what was laid out: nothing says when.
        await RealWait.pass(.milliseconds(300))
        host.layoutSubtreeIfNeeded()
        let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        let data = try #require(bitmap.representation(using: .png, properties: [:]))
        try data.write(to: URL(fileURLWithPath: path))
        window.orderOut(nil)
    }

    @Test func `the page, the source, and a file that changed on disk`() async throws {
        let out = try #require(ProcessInfo.processInfo.environment["SUNSET_CATALOG"])
        try FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
        let folder = NSTemporaryDirectory() + "catalog-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: folder) }
        try Self.sample.write(toFile: folder + "/tides.md", atomically: true, encoding: .utf8)
        try picture(at: folder + "/harbour.png")
        let documents = OpenDocuments(store: nil)
        let state = ["file": folder + "/tides.md"]
        let pane = try #require(
            DocumentContent(PaneDescriptor(kind: DocumentContent.kind, state: state), documents: documents)
        )
        let context = PaneViewContext(focused: true, translucent: false, optionAsMeta: false)
        let size = CGSize(width: 760, height: 900)
        pane.setState(focused: true, visible: true)
        try await draw(pane.makeView(context), size: size, to: out + "/mc-rendered.png")
        pane.toggleMode()
        try await draw(pane.makeView(context), size: size, to: out + "/mc-source.png")
        let storage = pane.document.source.storage
        storage.replaceCharacters(in: NSRange(location: storage.length, length: 0), with: "\nmine\n")
        try "theirs\n".write(toFile: folder + "/tides.md", atomically: true, encoding: .utf8)
        pane.document.checkFile()
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: folder)
        pane.save()
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: folder)
        try await draw(pane.makeView(context), size: CGSize(width: 760, height: 260), to: out + "/mc-notices.png")
        pane.stop()
    }
}
