package import AppKit
import ImageIO

/// A picture on a pasteboard (roadmap 0093 D): an image copied (a screenshot to the clipboard), or an image file copied in
/// the Finder; nil when there is none. Header dimensions are checked against `pixelLimit` before decoding (N-S8).
package enum PasteboardImage {
    /// Maximum decoded pixel count (64 MiB at four bytes per pixel), matching `ImageIODecoder.pixelLimit`.
    package static let pixelLimit = 1 << 24

    package static func image(in pasteboard: NSPasteboard = .general) -> CGImage? {
        if let image = (pasteboard.readObjects(forClasses: [NSImage.self]) as? [NSImage])?.first,
            let picture = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
            isWithinPixelLimit(width: picture.width, height: picture.height)
        {
            return picture
        }
        let files = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL]
        return files?.lazy.compactMap(image(at:)).first
    }

    package static func image(at url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return decodeBounded(source)
    }

    private static func decodeBounded(_ source: CGImageSource) -> CGImage? {
        guard CGImageSourceGetCount(source) > 0,
            let info = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = info[kCGImagePropertyPixelWidth] as? Int,
            let height = info[kCGImagePropertyPixelHeight] as? Int,
            isWithinPixelLimit(width: width, height: height),
            let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil),
            isWithinPixelLimit(width: cgImage.width, height: cgImage.height)
        else { return nil }
        return cgImage
    }

    package static func isWithinPixelLimit(width: Int, height: Int) -> Bool {
        guard width > 0, height > 0 else { return false }
        let (pixels, overflow) = width.multipliedReportingOverflow(by: height)
        return !overflow && pixels <= pixelLimit
    }
}
