import AppKit
import SunsetCore
import SunsetRender

/// Opening hyperlinks (OSC 8, ADR-0010): only on the user's Command-click, only the addresses the policy allows.
extension TerminalModel {
    /// Opens the link under a point of the surface, if there is one and it may be opened. Returns whether there was a link there (the click is then used up).
    @discardableResult
    func openLink(pixelX: Int, pixelY: Int) -> Bool {
        guard let screen = lastScreen, let metrics = renderer?.cellMetrics, let size = currentGrid() else {
            return false
        }
        let cell = metrics.cell(atPixelX: pixelX, pixelY: pixelY, columns: size.columns, rows: size.rows)
        guard let address = screen.viewportLink(row: cell.row, column: cell.column, scrolledBack: viewport.scrolledBack)
        else { return false }
        if HyperlinkPolicy.opens(address, localHost: ProcessInfo.processInfo.hostName), let url = URL(string: address) {
            NSWorkspace.shared.open(url)
        }
        return true
    }
}
