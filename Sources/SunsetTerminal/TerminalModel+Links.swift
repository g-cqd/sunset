import AppKit
import SunsetCore
import SunsetRender
import SunsetRenderMac

/// Opening hyperlinks (OSC 8, ADR-0010): only on the user's Command-click, only the addresses the policy allows.
extension TerminalModel {
    /// Opens the link under a point of the surface, if there is one and it may be opened. Returns whether there was a link there (the click is then used up).
    @discardableResult
    package func openLink(pixelX: Int, pixelY: Int) -> Bool {
        guard let screen = lastScreen, let metrics = renderer?.cellMetrics else {
            return false
        }
        let cell = metrics.cell(atPixelX: pixelX, pixelY: pixelY, columns: screen.columns, rows: screen.rows)
        guard let address = screen.viewportLink(row: cell.row, column: cell.column, scrolledBack: viewport.scrolledBack)
        else { return false }
        if HyperlinkPolicy.opens(address, localHost: ProcessInfo.processInfo.hostName), let url = URL(string: address) {
            openURL(url)
        }
        return true
    }

    /// The pointer is at a point of the surface (or left it: nil): the link there, if any, is the hovered one.
    package func hover(pixelX: Int?, pixelY: Int?) {
        var id: UInt16 = 0
        if let pixelX, let pixelY, let screen = lastScreen, let metrics = renderer?.cellMetrics {
            let cell = metrics.cell(atPixelX: pixelX, pixelY: pixelY, columns: screen.columns, rows: screen.rows)
            id = screen.viewportLinkID(row: cell.row, column: cell.column, scrolledBack: viewport.scrolledBack) ?? 0
        }
        guard id != hoveredLink else { return }
        hoveredLink = id
        requestFrame()
    }
}
