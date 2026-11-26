import Foundation
import SunsetCore
import SunsetRender
import SunsetRenderMac

/// Opening hyperlinks (OSC 8) and plain file paths (`path:line[:col]`, M-h / t211): only on the user's Command-click,
/// only the addresses the policy allows or regular files on disk.
extension TerminalModel {
    /// Opens the link or file path under a point of the surface, if there is one and it may be opened. Returns whether
    /// there was a link or existing file path there (the click is then used up).
    @discardableResult
    package func openLink(pixelX: Int, pixelY: Int) -> Bool {
        guard let screen = lastScreen, let metrics = renderer?.cellMetrics else {
            return false
        }
        let cell = metrics.cell(atPixelX: pixelX, pixelY: pixelY, columns: screen.columns, rows: screen.rows)
        if let address = screen.viewportLink(row: cell.row, column: cell.column, scrolledBack: viewport.scrolledBack) {
            if HyperlinkPolicy.opens(address, localHost: ProcessInfo.processInfo.hostName),
                let url = URL(string: address)
            {
                openURL(url)
            }
            return true
        }
        let lineText = screen.viewportText(row: cell.row, scrolledBack: viewport.scrolledBack)
        if let match = TerminalPathDetector.detect(
            in: lineText,
            at: cell.column,
            workingDirectory: screen.workingDirectory?.path
        ) {
            openURL(match.url)
            return true
        }
        return false
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
