package import AppKit

/// A picture on a pasteboard (roadmap 0093 D): an image copied (a screenshot to the clipboard), or an image file copied in
/// the Finder; nil when there is none.
package enum PasteboardImage {
    package static func image(in pasteboard: NSPasteboard = .general) -> CGImage? {
        if let image = (pasteboard.readObjects(forClasses: [NSImage.self]) as? [NSImage])?.first,
            let picture = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        {
            return picture
        }
        let files = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL]
        return files?.lazy.compactMap(image(at:)).first
    }

    package static func image(at url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
