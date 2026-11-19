import AppKit
@preconcurrency import ScreenCaptureKit

/// macOS's own picker of a screen, a window or an app (the owner, 2026-11-19: "clicking on screen and windows i'd expect to
/// get the native experience"; ADR-0085). WebKit, in an app, shows none: answered yes it takes the main screen or a window
/// of its choosing (probed). The picker needs no screen recording permission: what the person picks is what is shared.
final class ScreenPicker: NSObject, SCContentSharingPickerObserver, @unchecked Sendable {
    private let lock = NSLock()
    private var waiting: CheckedContinuation<Picked?, Never>?

    /// What was picked, handed once from the picker's thread to the main actor.
    private struct Picked: @unchecked Sendable { let filter: SCContentFilter }

    /// Shows the picker; the filter of what the person picked, or nil when they cancel.
    @MainActor func pick() async -> SCContentFilter? {
        let picker = SCContentSharingPicker.shared
        var configuration = SCContentSharingPickerConfiguration()
        configuration.allowedPickerModes = [.singleDisplay, .singleWindow, .singleApplication]
        picker.defaultConfiguration = configuration
        picker.add(self)
        picker.isActive = true
        let picked: Picked? = await withCheckedContinuation { continuation in
            lock.withLock { waiting = continuation }
            picker.present()
        }
        let filter = picked?.filter
        picker.remove(self)
        if filter == nil { picker.isActive = false }
        return filter
    }

    /// The picker no longer stands for a share running (its menu bar item goes).
    @MainActor static func done() {
        SCContentSharingPicker.shared.isActive = false
    }

    func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didUpdateWith filter: SCContentFilter,
        for stream: SCStream?
    ) {
        finish(filter)
    }

    func contentSharingPicker(_ picker: SCContentSharingPicker, didCancelFor stream: SCStream?) {
        finish(nil)
    }

    func contentSharingPickerStartDidFailWithError(_ error: any Error) {
        finish(nil)
    }

    private func finish(_ filter: SCContentFilter?) {
        let continuation = lock.withLock {
            defer { waiting = nil }
            return waiting
        }
        continuation?.resume(returning: filter.map(Picked.init))
    }
}
