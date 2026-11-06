import SunsetCore
import SunsetHost
import SunsetRender

extension TerminalModel {
    /// Keys, text and pastes go to the program one at a time, in the order they happened, encoded by the session for the modes it has *now*.
    func send(_ event: InputEvent) {
        cursorPhase = true
        lastActivity = .now
        if case .mouse = event {} else { clearSelection() }
        if !viewport.isLive {
            viewport.toLive()
            requestFrame()
        }
        input.continuation.yield(event)
    }

    /// The pointer did something at a point of the surface (device pixels, from the top left). Motion within one cell is not repeated, as terminals do not.
    func sendMouse(
        _ action: MouseEvent.Action,
        _ button: MouseEvent.Button,
        pixelX: Int,
        pixelY: Int,
        modifiers: InputModifiers
    ) {
        guard let metrics = renderer?.cellMetrics, let grid = currentGrid() else { return }
        let cell = metrics.cell(atPixelX: pixelX, pixelY: pixelY, columns: grid.columns, rows: grid.rows)
        if action == .motion {
            if let last = lastMotionCell, last == cell { return }
            lastMotionCell = cell
        } else {
            lastMotionCell = cell
        }
        let inGrid = metrics.gridPixel(x: pixelX, y: pixelY, columns: grid.columns, rows: grid.rows)
        input.continuation.yield(
            .mouse(
                MouseEvent(
                    action,
                    button,
                    column: cell.column,
                    row: cell.row,
                    modifiers: modifiers,
                    pixelX: inGrid.x,
                    pixelY: inGrid.y
                )
            )
        )
    }

    static func forward(
        _ events: AsyncStream<InputEvent>,
        to session: TerminalSession,
        unclaimed: @MainActor (MouseEvent) -> Void
    ) async {
        for await event in events {
            switch event {
                case .key(let press): await session.send(press)
                case .text(let text): await session.send(text: text)
                case .paste(let text): await session.paste(text)
                case .mouse(let event): if await !session.send(event) { unclaimed(event) }
            }
        }
    }

    /// A mouse event the program did not ask for: the wheel scrolls the history.
    func unclaimed(_ event: MouseEvent) {
        guard event.action == .press else { return }
        switch event.button {
            case .wheelUp: scroll(byLines: 1)
            case .wheelDown: scroll(byLines: -1)
            default: break
        }
    }

    /// Scrolls the window into the history (positive) or back toward the live screen.
    func scroll(byLines lines: Int) {
        let before = viewport.scrolledBack
        viewport.scroll(by: lines)
        if viewport.scrolledBack != before { requestFrame() }
    }

    func scroll(byPages pages: Int) { scroll(byLines: pages * max(1, (currentGrid()?.rows ?? 24) - 1)) }

    func scrollToLive() {
        guard !viewport.isLive else { return }
        viewport.toLive()
        requestFrame()
    }
}
