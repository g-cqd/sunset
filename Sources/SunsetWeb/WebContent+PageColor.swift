import AppKit
import SunsetShell
import WebKit

/// The colour behind the page (`WKWebView.underPageBackgroundColor`, which WebKit derives from the page's own background): the
/// strip above a page that reaches the window's top is drawn in it, so that it reads as the page's and not as a black bar.
extension WebContent {
    func observePageColor(_ view: WKWebView) -> NSKeyValueObservation {
        view.observe(\.underPageBackgroundColor, options: [.initial, .new]) { [weak self] view, _ in
            MainActor.assumeIsolated { self?.pageBackground = view.underPageBackgroundColor }
        }
    }

    /// The page's declared theme colour, followed.
    func observeThemeColor(_ view: WKWebView) -> NSKeyValueObservation {
        view.observe(\.themeColor, options: [.initial, .new]) { [weak self] view, _ in
            MainActor.assumeIsolated { self?.themeColor = view.themeColor.flatMap(Self.bytes) }
        }
    }

    /// A colour as sRGB bytes.
    static func bytes(_ colour: NSColor) -> [UInt8]? {
        guard let srgb = colour.usingColorSpace(.sRGB) else { return nil }
        return [srgb.redComponent, srgb.greenComponent, srgb.blueComponent].map { UInt8(max(0, min(1, $0)) * 255) }
    }

    /// An icon's colour: its most common colourful one, read at 32 × 32.
    static func colour(of image: NSImage) -> [UInt8]? {
        let side = 32
        guard
            let context = CGContext(
                data: nil,
                width: side,
                height: side,
                bitsPerComponent: 8,
                bytesPerRow: side * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ), let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let data = context.data else { return nil }
        let pixels = Array(UnsafeBufferPointer(start: data.assumingMemoryBound(to: UInt8.self), count: side * side * 4))
        return Design.Accent.dominant(rgba: pixels)
    }
}
