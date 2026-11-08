import SunsetCore
import SunsetRender
import SunsetRenderMac

/// Selecting text with the pointer, and what to do with it.
extension TerminalModel {
    /// The pointer did something at a point of the surface. The program gets it when it asked for the mouse (holding Shift takes it back, as in other
    /// terminals); the wheel always goes to `sendMouse`, which decides between the program and the history; otherwise the left button selects text.
    func pointer(
        _ action: MouseEvent.Action,
        _ button: MouseEvent.Button,
        pixelX: Int,
        pixelY: Int,
        modifiers: InputModifiers,
        clickCount: Int
    ) {
        hover(pixelX: pixelX, pixelY: pixelY)
        let isWheel = button != .left && button != .right && button != .middle && button != .none
        if isWheel || (programHasMouse && !modifiers.contains(.shift)) {
            sendMouse(action, button, pixelX: pixelX, pixelY: pixelY, modifiers: modifiers)
            return
        }
        guard button == .left, let screen = lastScreen, let point = selectionPoint(pixelX: pixelX, pixelY: pixelY)
        else { return }
        switch action {
            case .press:
                let granularity: SelectionGesture.Granularity =
                    clickCount >= 3 ? .lines : clickCount == 2 ? .words : .cells
                let started = SelectionGesture(
                    at: point,
                    granularity: granularity,
                    shape: modifiers.contains(.option) ? .block : .linear,
                    screen: screen
                )
                gesture = started
                setSelection(started.selection)
            case .motion:
                guard let gesture else { return }
                setSelection(gesture.dragged(to: point, screen: screen))
            case .release:
                gesture = nil
        }
    }

    /// The text place under a pixel of the surface.
    private func selectionPoint(pixelX: Int, pixelY: Int) -> SelectionPoint? {
        guard let metrics = renderer?.cellMetrics, let size = currentGrid() else { return nil }
        let cell = metrics.cell(atPixelX: pixelX, pixelY: pixelY, columns: size.columns, rows: size.rows)
        return SelectionPoint(line: viewport.firstLine + cell.row, column: cell.column)
    }

    private func setSelection(_ new: Selection?) {
        guard new != selection else { return }
        selection = new
        hasSelection = new != nil
        requestFrame()
    }

    func clearSelection() {
        gesture = nil
        setSelection(nil)
    }

    func selectAll() {
        guard let screen = lastScreen else { return }
        setSelection(
            Selection(
                anchor: SelectionPoint(line: 0, column: 0),
                head: SelectionPoint(line: screen.absoluteLineCount - 1, column: screen.columns - 1)
            )
        )
    }

    /// The selected text, or nil when nothing is selected.
    var selectedText: String? {
        guard let selection, let screen = lastScreen else { return nil }
        let text = screen.text(of: selection)
        return text.isEmpty ? nil : text
    }
}
