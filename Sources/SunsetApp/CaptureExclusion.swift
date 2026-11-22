import AppKit
import SwiftUI

/// Leaves the window it is in out of screen capture and sharing while `excluded` (`NSWindow.sharingType = .none`): what
/// shows an unlocked vault (roadmap 0091 D). Put back when it is no longer, or goes.
struct CaptureExclusion: NSViewRepresentable {
    let excluded: Bool

    func makeNSView(context: Context) -> NSView {
        ExclusionView()
    }

    func updateNSView(_ view: NSView, context: Context) {
        (view as? ExclusionView)?.excluded = excluded
    }

    static func dismantleNSView(_ view: NSView, coordinator: ()) {
        (view as? ExclusionView)?.excluded = false
    }

    final class ExclusionView: NSView {
        var excluded = false {
            didSet {
                apply()
            }
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            apply()
        }

        private func apply() {
            window?.sharingType = excluded ? .none : .readOnly
        }
    }
}
