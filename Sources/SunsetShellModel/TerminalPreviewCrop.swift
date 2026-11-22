package import CoreGraphics

/// The part of a terminal's frame a share card shows: its top-left, as wide as `columns` cells and as high as the card's
/// ratio makes it. A whole window shrunk to a card leaves glyphs a pixel or two tall; text starts at the top left.
package enum TerminalPreviewCrop {
    /// The columns a card shows: a classic terminal's width.
    package static let columns = 80

    /// The rectangle in `frame`'s pixels, its origin at the bottom left (Core Image's), of the part shown.
    /// - Parameters:
    ///   - frame: the frame's size in pixels.
    ///   - cellWidth: a cell's width in pixels; nil or 0 shows the whole frame.
    ///   - padding: the pixels around the grid.
    ///   - ratio: the card's height over its width (`Design.Optical.sharePreviewRatio`).
    /// - Returns: the whole frame when the cells' width is not known yet.
    package static func rect(frame: CGSize, cellWidth: Int?, padding: Int, ratio: Double) -> CGRect {
        guard let cellWidth, cellWidth > 0 else { return CGRect(origin: .zero, size: frame) }
        let width = min(frame.width, CGFloat(2 * padding + columns * cellWidth))
        let height = min(frame.height, width * ratio)
        return CGRect(x: 0, y: frame.height - height, width: width, height: height)
    }
}
