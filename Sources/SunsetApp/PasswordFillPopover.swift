import AppKit
import SunsetShell
import SwiftUI

/// The borderless panel filling and saving show (`AppPasswordFill`): no arrow, continuous rounded corners concentric
/// with `FillMenuRow` (`FillMenuRow.panelRadius` = 12 pt = 6 pt row corner + 6 pt inset), transient (dismissed on outside
/// click, Escape, or window resign), and non-activating by default so the page keeps keyboard focus until an inline field
/// (such as `VaultUnlockOffer`'s master-password input) explicitly requests key focus.
@MainActor
final class PasswordFillPopover {
    private var panel: Panel?
    private weak var hostView: NSView?
    private var anchorRect: CGRect = .zero
    private var monitors: [Any] = []
    private var windowObservers: [any NSObjectProtocol] = []
    /// Whether what is shown is suggestions (closed when their field loses the keyboard, unless the panel itself took key focus).
    private var suggesting = false

    func show(_ content: some View, at rect: CGRect, of view: NSView, edge: NSRectEdge, suggestions: Bool = false) {
        close()
        guard let parentWindow = view.window, !view.isHiddenOrHasHiddenAncestor else { return }
        let shape = RoundedRectangle(cornerRadius: FillMenuRow.panelRadius, style: .continuous)
        let styled =
            content
            .foregroundStyle(.primary)
            .background(Color(nsColor: .windowBackgroundColor), in: shape)
            .clipShape(shape)
            .overlay { shape.strokeBorder(.separator, lineWidth: 1) }
        let hosting = NSHostingView(rootView: styled)
        hosting.sizingOptions = [.intrinsicContentSize]
        let panel = Panel(contentView: hosting)
        panel.onResize = { [weak self] in self?.reposition() }
        panel.onCancel = { [weak self] in self?.close() }
        self.panel = panel
        hostView = view
        anchorRect = rect
        suggesting = suggestions
        reposition()
        parentWindow.addChildWindow(panel, ordered: .above)
        panel.orderFront(nil)
        installDismissMonitors(for: parentWindow)
    }

    /// Lets an inline text field inside the panel (such as master-password unlock) become first responder without
    /// treating the web view's resulting blur as a dismissal.
    func makeKey() {
        guard let panel else { return }
        panel.allowsKey = true
        panel.makeKeyAndOrderFront(nil)
    }

    func closeSuggestions() {
        // When the person clicked into the panel to type their master password, the page's field blurs; keep the panel open!
        if panel?.isKeyWindow == true { return }
        if suggesting { close() }
    }

    func close() {
        removeDismissMonitors()
        if let panel {
            let restoreView = panel.isKeyWindow ? hostView : nil
            panel.parent?.removeChildWindow(panel)
            panel.orderOut(nil)
            if let restoreView, let window = restoreView.window {
                window.makeFirstResponder(restoreView)
            }
        }
        panel = nil
        hostView = nil
        suggesting = false
    }

    private func reposition() {
        guard let panel, let view = hostView, let window = view.window, let contentView = panel.contentView else {
            return
        }
        let fitting = contentView.fittingSize
        let size = CGSize(width: max(fitting.width, 120), height: max(fitting.height, 32))
        let inWindow = view.convert(anchorRect, to: nil)
        let fieldOnScreen = window.convertToScreen(inWindow)
        let gap = Design.Space.xs
        var x = fieldOnScreen.minX
        var y = fieldOnScreen.minY - gap - size.height
        if let screen = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame {
            if y < screen.minY + Design.Space.s {
                y = fieldOnScreen.maxY + gap
            }
            x = min(max(x, screen.minX + Design.Space.s), screen.maxX - Design.Space.s - size.width)
            y = min(max(y, screen.minY + Design.Space.s), screen.maxY - Design.Space.s - size.height)
        }
        panel.setFrame(CGRect(origin: CGPoint(x: x.rounded(), y: y.rounded()), size: size), display: true)
    }

    private func installDismissMonitors(for parentWindow: NSWindow) {
        let local = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown, .keyDown],
            handler: { [weak self] event in
                guard let self, let panel = self.panel else { return event }
                if event.type == .keyDown {
                    if event.keyCode == 53 {
                        self.close()
                        return panel.isKeyWindow ? nil : event
                    }
                    return event
                }
                if event.window !== panel {
                    self.close()
                }
                return event
            }
        )
        if let local {
            monitors.append(local)
        }
        let nc = NotificationCenter.default
        windowObservers.append(
            nc.addObserver(forName: NSWindow.didResignKeyNotification, object: parentWindow, queue: .main) {
                [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    if self.panel?.isKeyWindow == true { return }
                    self.close()
                }
            }
        )
        windowObservers.append(
            nc.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) {
                [weak self] _ in
                MainActor.assumeIsolated { self?.close() }
            }
        )
    }

    private func removeDismissMonitors() {
        for monitor in monitors { NSEvent.removeMonitor(monitor) }
        monitors.removeAll()
        for obs in windowObservers { NotificationCenter.default.removeObserver(obs) }
        windowObservers.removeAll()
    }
}

extension PasswordFillPopover {
    fileprivate final class Panel: NSPanel {
        var allowsKey = false
        var onResize: () -> Void = {}
        var onCancel: () -> Void = {}
        private var lastFitting: CGSize = .zero

        init(contentView: NSView) {
            super
                .init(
                    contentRect: CGRect(origin: .zero, size: CGSize(width: 264, height: 48)),
                    styleMask: [.borderless, .nonactivatingPanel],
                    backing: .buffered,
                    defer: false
                )
            isOpaque = false
            backgroundColor = .clear
            hasShadow = true
            level = .popUpMenu
            isReleasedWhenClosed = false
            hidesOnDeactivate = true
            self.contentView = contentView
        }

        override var canBecomeKey: Bool {
            allowsKey
        }

        override var canBecomeMain: Bool {
            false
        }

        override func layoutIfNeeded() {
            super.layoutIfNeeded()
            guard let fitting = contentView?.fittingSize, fitting != lastFitting else { return }
            lastFitting = fitting
            onResize()
        }

        override func cancelOperation(_ sender: Any?) {
            onCancel()
        }
    }
}
