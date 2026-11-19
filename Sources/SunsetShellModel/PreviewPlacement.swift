package import CoreGraphics

/// Where the hover preview of a tab goes (n47): beside a sidebar row, level with it, on the sidebar's side; above or below a row of the built-in bar, at its
/// place along the bar; always inside the pane area.
package enum PreviewPlacement {
    /// Where the preview's top left corner goes, in the area's coordinates; `panel`: the sidebar's frame, in the row's.
    package static func origin(
        size: CGSize,
        row: CGRect?,
        area: CGRect,
        sidebarOnRight: Bool,
        panel: CGRect? = nil
    ) -> CGPoint {
        let margin = 12.0
        let maxX = max(area.width - size.width - margin, margin)
        let maxY = max(area.height - size.height - margin, margin)
        guard let row else { return CGPoint(x: sidebarOnRight ? maxX : margin, y: margin) }
        if row.midY >= area.minY, row.midY <= area.maxY {
            // A row of the sidebar, docked beside the area or floating over it: next to the row's outer edge, level with it, so
            // never under a floating panel (owner, 2026-11-13, t228).
            let y = min(max(row.midY - area.minY - size.height / 2, margin), maxY)
            // Beside the sidebar's edge when it is known, not the row's: a Pinned tile, an indented or grouped row is inside
            // the panel, and a card beside it went under a floating one (roadmap 0047 B).
            let edge = panel ?? row
            let beside = sidebarOnRight ? edge.minX - area.minX - size.width - margin : edge.maxX - area.minX + margin
            return CGPoint(x: min(max(beside, margin), maxX), y: y)
        }
        // A row of the built-in bar, above or below the area: at its place along the bar, on the bar's side.
        let x = min(max(row.midX - area.minX - size.width / 2, margin), maxX)
        return CGPoint(x: x, y: row.midY < area.midY ? margin : maxY)
    }
}
