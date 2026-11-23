public import AppKit
import SunsetRuntime
import SunsetShellModel

/// A long press, or a deep press on a Force Touch trackpad, opens the menu a right click would, wherever one is (the
/// owner's note n112): the press is sent again as a right click where it was. Not in a page, a terminal or a field of
/// text, which have their own long and deep presses (Look Up, a link's preview, a selection held).
@MainActor
public enum LongPressMenus {
    private static var monitor: Any?
    private static var press: LongPress?
    private static var pressEvent: NSEvent?
    private static var timer: Timer?

    public static func start() {
        guard monitor == nil else { return }
        let kinds: NSEvent.EventTypeMask = [.leftMouseDown, .leftMouseDragged, .leftMouseUp, .pressure]
        monitor = NSEvent.addLocalMonitorForEvents(matching: kinds) { event in
            follow(event) ? nil : event
        }
    }

    /// Follows the press; true when the event opened a menu and goes no further.
    private static func follow(_ event: NSEvent) -> Bool {
        switch event.type {
            case .leftMouseDown:
                begin(event)
            case .leftMouseDragged:
                press?.moved(to: event.locationInWindow)
            case .leftMouseUp:
                end()
            case .pressure where event.stage >= 2:
                guard press?.deepPressed() == true, let down = pressEvent else { return false }
                end()
                openMenu(like: down)
                return true
            default:
                break
        }
        return false
    }

    private static func begin(_ event: NSEvent) {
        end()
        guard event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty, takes(event) else {
            return
        }
        press = LongPress(at: event.locationInWindow, time: Runtime.live.uptime())
        pressEvent = event
        timer = Timer.scheduledTimer(
            withTimeInterval: Double(LongPress.hold.components.attoseconds) / 1e18,
            repeats: false
        ) { _ in
            MainActor.assumeIsolated {
                guard press?.isDue(at: Runtime.live.uptime()) == true, let down = pressEvent else { return }
                end()
                // The press still held: its button's release must not click what the menu covers.
                openMenu(like: down)
            }
        }
    }

    private static func end() {
        timer?.invalidate()
        timer = nil
        press?.end()
        press = nil
        pressEvent = nil
    }

    /// Views of modules that do not see this one, with presses of their own: a terminal (a press held selects, and its
    /// program may read the mouse).
    private static let ownPresses: Set<String> = ["TerminalNSView"]

    /// Whether the press is on something whose menu it may open: not text, a page or a terminal.
    private static func takes(_ event: NSEvent) -> Bool {
        guard let window = event.window, let hit = window.contentView?.hitTest(event.locationInWindow) else {
            return false
        }
        var view: NSView? = hit
        while let current = view {
            if current is NSTextView || current is NSTextField || current.acceptsLongPressItself
                || ownPresses.contains(String(describing: type(of: current)))
            {
                return false
            }
            view = current.superview
        }
        return true
    }

    /// A right click where `down` was, as the system sends one: the view under it opens its menu.
    private static func openMenu(like down: NSEvent) {
        guard let window = down.window,
            let right = NSEvent.mouseEvent(
                with: .rightMouseDown,
                location: down.locationInWindow,
                modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber,
                context: nil,
                eventNumber: 0,
                clickCount: 1,
                pressure: 1
            )
        else { return }
        Feedback.snapped()
        window.sendEvent(right)
    }
}

extension NSView {
    /// A view with its own long or deep press (a page, a terminal): `LongPressMenus` leaves it.
    @objc open var acceptsLongPressItself: Bool {
        false
    }
}
