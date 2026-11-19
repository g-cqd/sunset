package import CoreGraphics

/// A picture the window's model holds (a site's icon) without a UI framework: its pixels and the size it is shown at.
package struct PanePicture: Equatable, @unchecked Sendable {
    package let image: CGImage
    /// Its size in points (its pixels at the screen's scale).
    package let size: CGSize

    package init(_ image: CGImage, size: CGSize) {
        self.image = image
        self.size = size
    }

    package static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.image === rhs.image && lhs.size == rhs.size
    }
}
