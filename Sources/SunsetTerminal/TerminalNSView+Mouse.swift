package import AppKit
package import SunsetCore

extension TerminalNSView {
    /// A click in the strip drags the window even when the window is not the active one, as a title bar does. Elsewhere the click that activates the
    /// window is taken too, but only to give this pane the keyboard (`n44`: in a split, the pane clicked is the one typed in next); it is remembered
    /// here, by its number, so that `mouseDown` does not also hand it to the program or start a selection with it.
    package override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        guard let event else { return false }
        if !isInDragStrip(event) { activatingClick = event.eventNumber }
        return true
    }

    /// Whether `event` is the press that activated the window: this pane takes the keyboard, and the press, its drag and its release go no further.
    private func takesFocusOnly(_ event: NSEvent) -> Bool {
        guard activatingClick == event.eventNumber else {
            activatingClick = nil
            return false
        }
        activatingClick = nil
        ignoringActivatingClick = true
        window?.makeFirstResponder(self)
        return true
    }

    private func isInDragStrip(_ event: NSEvent) -> Bool {
        guard model.topInsetPoints > 0 else { return false }
        let point = convert(event.locationInWindow, from: nil)
        let fromTop = isFlipped ? point.y : bounds.height - point.y
        return fromTop >= 0 && fromTop <= model.topInsetPoints
    }

    /// A press in the strip at the top of a window with no title bar drags the window (a double-click zooms it, as a title bar does).
    private func dragsWindow(_ event: NSEvent) -> Bool {
        guard let window, isInDragStrip(event) else { return false }
        if event.clickCount == 2 {
            window.performZoom(nil)
        } else {
            window.performDrag(with: event)
        }
        return true
    }

    package override func mouseDown(with event: NSEvent) {
        if takesFocusOnly(event) { return }
        ignoringActivatingClick = false
        if dragsWindow(event) { return }
        if event.modifierFlags.contains(.command) {
            let point = convert(event.locationInWindow, from: nil)
            let scale = window?.backingScaleFactor ?? 2
            if model.openLink(
                pixelX: Int((point.x * scale).rounded(.down)),
                pixelY: Int((point.y * scale).rounded(.down))
            ) {
                return
            }
        }
        report(.press, .left, event)
    }
    package override func mouseUp(with event: NSEvent) {
        if ignoringActivatingClick {
            ignoringActivatingClick = false
        } else {
            report(.release, .left, event)
        }
    }
    package override func mouseDragged(with event: NSEvent) {
        if !ignoringActivatingClick { report(.motion, .left, event) }
    }
    package override func rightMouseDown(with event: NSEvent) { report(.press, .right, event) }
    package override func rightMouseUp(with event: NSEvent) { report(.release, .right, event) }
    package override func rightMouseDragged(with event: NSEvent) { report(.motion, .right, event) }

    package override func otherMouseDown(with event: NSEvent) { report(.press, .middle, event) }
    package override func otherMouseUp(with event: NSEvent) { report(.release, .middle, event) }
    package override func otherMouseDragged(with event: NSEvent) { report(.motion, .middle, event) }

    package override func mouseMoved(with event: NSEvent) {
        refreshPointer()
        report(.motion, .none, event)
    }

    /// The pointer the program asked for over its screen (OSC 22); none, and the system's arrow stays.
    package override func resetCursorRects() {
        if let shape = model.lastScreen?.pointerShape { addCursorRect(bounds, cursor: shape.cursor) }
    }

    /// Looks whether the program changed the pointer since it was last applied: with each frame, and when the mouse moves (a change of the pointer alone
    /// draws no frame).
    package func refreshPointer() {
        let shape = model.lastScreen?.pointerShape
        guard shape != shownPointer else { return }
        shownPointer = shape
        window?.invalidateCursorRects(for: self)
    }
    package override func mouseExited(with event: NSEvent) { model.hover(pixelX: nil, pixelY: nil) }

    package override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    package func report(_ action: MouseEvent.Action, _ button: MouseEvent.Button, _ event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let scale = window?.backingScaleFactor ?? 2
        model.pointer(
            action,
            button,
            pixelX: Int((point.x * scale).rounded(.down)),
            pixelY: Int((point.y * scale).rounded(.down)),
            modifiers: KeyboardMapping.modifiers(event.modifierFlags),
            clickCount: Self.clickCount(of: event)
        )
    }

    /// `NSEvent.clickCount` is only valid for mouse button events: asking a scroll wheel or a moved-pointer event raises an Objective-C exception, which
    /// AppKit swallows and which ended `report` before it reached the model, so that the wheel never scrolled the history.
    private static func clickCount(of event: NSEvent) -> Int {
        switch event.type {
            case .leftMouseDown, .leftMouseUp, .leftMouseDragged, .rightMouseDown, .rightMouseUp, .rightMouseDragged,
                .otherMouseDown, .otherMouseUp, .otherMouseDragged:
                event.clickCount
            default:
                0
        }
    }
}
