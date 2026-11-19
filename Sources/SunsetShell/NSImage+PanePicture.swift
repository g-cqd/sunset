package import AppKit

extension NSImage {
    /// The image as a picture the window's model holds (`PanePicture`): its pixels and its size in points; nil when it
    /// has no bitmap to give.
    package var panePicture: PanePicture? {
        cgImage(forProposedRect: nil, context: nil, hints: nil).map { PanePicture($0, size: size) }
    }
}
