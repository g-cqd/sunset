import AppKit
import SunsetShell
import WebKit

/// An extension's popup in a panel of Sunset's own ("decrease the corner radius of the popup"): the popover WebKit made for
/// it is not shown; its content, sized by the page, sits in a panel with a smaller corner, under the button that was
/// clicked. Closed when it loses the keyboard or on Escape.
@MainActor final class ExtensionPopupPanel: NSPanel {
    private static var shown: ExtensionPopupPanel?
    private let action: WKWebExtension.Action
    private var sizeWatch: NSKeyValueObservation?
    private weak var anchor: NSView?

    static func show(_ action: WKWebExtension.Action, under anchor: NSView) {
        shown?.close()
        guard let content = action.popupPopover?.contentViewController, anchor.window != nil else { return }
        let panel = ExtensionPopupPanel(action: action, content: content, anchor: anchor)
        shown = panel
        panel.place(size: content.preferredContentSize)
        panel.makeKeyAndOrderFront(nil)
    }

    private init(action: WKWebExtension.Action, content: NSViewController, anchor: NSView) {
        self.action = action
        self.anchor = anchor
        super.init(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .popUpMenu
        isReleasedWhenClosed = false
        let backdrop = NSVisualEffectView()
        backdrop.material = .popover
        backdrop.state = .active
        backdrop.wantsLayer = true
        backdrop.layer?.cornerRadius = Design.Size.extensionPopupRadius
        backdrop.layer?.cornerCurve = .continuous
        backdrop.layer?.masksToBounds = true
        content.view.frame = backdrop.bounds
        content.view.autoresizingMask = [.width, .height]
        backdrop.addSubview(content.view)
        contentView = backdrop
        // The page measures itself after it loads: the panel follows, its top kept under the button.
        sizeWatch = content.observe(\.preferredContentSize, options: [.new]) { [weak self] content, _ in
            MainActor.assumeIsolated { self?.place(size: content.preferredContentSize) }
        }
    }

    override var canBecomeKey: Bool {
        true
    }

    /// Under the button, its middle on the button's, kept on the screen.
    private func place(size wanted: CGSize) {
        let size = wanted.width > 0 && wanted.height > 0 ? wanted : CGSize(width: 360, height: 420)
        guard let anchor, let window = anchor.window else { return }
        let button = window.convertToScreen(anchor.convert(anchor.bounds, to: nil))
        var frame = CGRect(
            x: button.midX - size.width / 2,
            y: button.minY - Design.Space.xs - size.height,
            width: size.width,
            height: size.height
        )
        if let screen = window.screen?.visibleFrame {
            frame.origin.x = min(
                max(frame.minX, screen.minX + Design.Space.s),
                screen.maxX - Design.Space.s - frame.width
            )
            frame.origin.y = max(frame.minY, screen.minY + Design.Space.s)
        }
        setFrame(frame, display: true)
    }

    override func resignKey() {
        super.resignKey()
        close()
    }

    override func cancelOperation(_ sender: Any?) {
        close()
    }

    override func close() {
        sizeWatch = nil
        action.closePopup()
        if Self.shown === self { Self.shown = nil }
        super.close()
    }
}
