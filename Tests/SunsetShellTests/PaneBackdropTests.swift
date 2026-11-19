import AppKit
import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// What is behind a pane's content (the owner, 2026-11-15): "background for documents and all other panes should use the same
/// background we use for terminals screens". The terminal's default background and how opaque it is, given to every pane.
@MainActor @Suite("The background of a pane") struct PaneBackdropTests {
    /// The middle of `view` drawn 20 pt square, as sRGB bytes (red, green, blue, alpha), not premultiplied.
    func pixel(_ view: some View) throws -> [Double] {
        let renderer = ImageRenderer(content: view.frame(width: 20, height: 20))
        renderer.scale = 1
        let image = try #require(renderer.cgImage)
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(
            CGContext(
                data: nil,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.draw(image, in: CGRect(x: -10, y: -10, width: 20, height: 20))
        let bytes = try #require(context.data).assumingMemoryBound(to: UInt8.self)
        let alpha = Double(unsafe bytes[3]) / 255
        guard alpha > 0 else { return [0, 0, 0, 0] }
        return unsafe [Double(bytes[0]) / alpha, Double(bytes[1]) / alpha, Double(bytes[2]) / alpha, alpha]
    }

    @Test func `it is the theme's background, and the terminal's own black with none or a wrong one`() {
        #expect(PaneBackdrop(rgb: [10, 20, 200], alpha: 1) == PaneBackdrop(red: 10, green: 20, blue: 200, alpha: 1))
        #expect(PaneBackdrop(rgb: nil, alpha: 1) == .black)
        #expect(PaneBackdrop(rgb: [1, 2], alpha: 1) == .black)
        #expect(PaneBackdrop(rgb: nil, alpha: 0.5).alpha == 0.5)
    }

    @Test func `its colour scheme is the one its text is read on: dark on a dark background, light on a light one`() {
        #expect(PaneBackdrop.black.scheme == .dark)
        #expect(PaneBackdrop(rgb: [30, 30, 46], alpha: 1).scheme == .dark)
        #expect(PaneBackdrop(rgb: [253, 246, 227], alpha: 1).scheme == .light)
    }

    @Test func `a pane's content is drawn on it`() throws {
        let colour = try pixel(Color.clear.paneBackdrop(PaneBackdrop(rgb: [10, 20, 200], alpha: 1)))
        #expect(abs(colour[0] - 10) <= 2 && abs(colour[1] - 20) <= 2 && abs(colour[2] - 200) <= 2, "\(colour)")
        #expect(colour[3] > 0.99)
    }

    @Test func `as translucent as the terminal is over a window that is not opaque`() throws {
        let colour = try pixel(Color.clear.paneBackdrop(PaneBackdrop(rgb: [255, 255, 255], alpha: 0.5)))
        #expect(abs(colour[3] - 0.5) < 0.02, "\(colour)")
    }

    /// Measured in the app (diary 2026-11-15-02): with `terminal.opacity` 0.2 over the window's 44 grey a terminal is 27 and a
    /// document drawn once at 0.2 was 35. A terminal has its background twice, its layer's colour and its frame's pixels.
    @Test func `it is as opaque as a terminal is seen, whose background is composed twice`() {
        #expect(PaneBackdrop(rgb: nil, terminalAlpha: 255).alpha == 1)
        #expect(PaneBackdrop(rgb: nil, terminalAlpha: 0).alpha == 0)
        #expect(abs(PaneBackdrop(rgb: nil, terminalAlpha: 51).alpha - 0.36) < 0.001)
        #expect(abs(PaneBackdrop(rgb: nil, terminalAlpha: 128).alpha - 0.752) < 0.001)
    }

    @Test func `the context of a pane has the terminal's black until it is told`() {
        #expect(PaneViewContext(focused: true, translucent: false, optionAsMeta: false).backdrop == .black)
        let backdrop = PaneBackdrop(rgb: [253, 246, 227], alpha: 1)
        let context = PaneViewContext(focused: true, translucent: false, optionAsMeta: false, backdrop: backdrop)
        #expect(context.backdrop == backdrop)
    }
}
