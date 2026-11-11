package import CoreGraphics

/// Where the hover preview of a tab goes (n47): beside a sidebar row, level with it, on the sidebar's side; above or below a row of the built-in bar, at its
/// place along the bar; always inside the pane area.
package enum PreviewPlacement {
    /// Where the preview's top left corner goes, in the area's coordinates.
    package static func origin(size: CGSize, row: CGRect?, area: CGRect, sidebarOnRight: Bool) -> CGPoint {
        let margin = 12.0
        let maxX = max(area.width - size.width - margin, margin)
        let maxY = max(area.height - size.height - margin, margin)
        guard let row else { return CGPoint(x: sidebarOnRight ? maxX : margin, y: margin) }
        if row.midY >= area.minY, row.midY <= area.maxY, row.maxX <= area.minX + 1 || row.minX >= area.maxX - 1 {
            // A row of the sidebar, beside the area: next to it, level with it.
            let y = min(max(row.midY - area.minY - size.height / 2, margin), maxY)
            return CGPoint(x: sidebarOnRight ? maxX : margin, y: y)
        }
        // A row of the built-in bar, above or below the area: at its place along the bar, on the bar's side.
        let x = min(max(row.midX - area.minX - size.width / 2, margin), maxX)
        return CGPoint(x: x, y: row.midY < area.midY ? margin : maxY)
    }
}
