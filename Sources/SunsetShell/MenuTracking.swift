package import AppKit
import Observation

/// Whether a menu of the app is open (`NSMenu`'s tracking notifications): a hover is held while it is (`HoverKeeper`).
@MainActor
@Observable
package final class MenuTracking {
    package static let shared = MenuTracking()

    package private(set) var isOpen = false
    @ObservationIgnored private var depth = 0

    private init() {
        let center = NotificationCenter.default
        center.addObserver(forName: NSMenu.didBeginTrackingNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { MenuTracking.shared.changed(by: 1) }
        }
        center.addObserver(forName: NSMenu.didEndTrackingNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { MenuTracking.shared.changed(by: -1) }
        }
    }

    private func changed(by step: Int) {
        depth = max(0, depth + step)
        isOpen = depth > 0
    }
}
