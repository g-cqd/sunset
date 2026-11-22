import Foundation
import SunsetRuntime
package import SunsetShell
import SwiftUI
import WebKit

/// A page's questions to the person: answered from what the site was given, else asked in the panel, one at a time.
extension WebContent {
    /// Whether the page may have all of `permissions`: a kept Deny refuses at once, a kept Allow grants at once, else the panel asks. Without
    /// Sunset.app's identity, what macOS must also allow is refused, the panel saying why.
    func ask(_ permissions: [SitePermission], host: String) async -> Bool {
        let store = self.permissions
        let answers = permissions.map { store.answer($0, for: host) }
        if answers.contains(.deny) { return false }
        let unavailable = !settings.hasAppIdentity && permissions.contains(where: \.needsAppIdentity)
        if answers.allSatisfy({ $0 == .allow }), !unavailable { return true }
        // One question at a time: a newer one waits for the one shown.
        while permissionRequest != nil { await runtime.sleep(for: .milliseconds(200)) }
        return await withCheckedContinuation { continuation in
            permissionRequest = PermissionRequest(permissions: permissions, host: host, unavailable: unavailable) {
                [weak self] granted in
                self?.permissionRequest = nil
                continuation.resume(returning: granted)
            }
        }
    }

    /// The site of the page, for its answers.
    var siteHost: String? {
        url?.host() ?? webView?.url?.host()
    }

    func captureChanged(_ view: WKWebView) {
        let active = view.cameraCaptureState != .none || view.microphoneCaptureState != .none
        if active { capture = .cameraOrMicrophone } else if capture == .cameraOrMicrophone { capture = nil }
        devices = PaneCapture(
            microphone: Self.state(view.microphoneCaptureState),
            camera: Self.state(view.cameraCaptureState)
        )
    }

    private static func state(_ state: WKMediaCaptureState) -> PaneCapture.State? {
        switch state {
            case .active: .live
            case .muted: .muted
            default: nil
        }
    }

    /// Mutes the microphone or the camera, or turns it back on (WebKit keeps the page's stream; it gets silence or black).
    package func toggle(_ device: PaneCapture.Device) {
        guard let webView, let now = devices[device] else { return }
        let next: WKMediaCaptureState = now == .live ? .muted : .active
        switch device {
            case .microphone: webView.setMicrophoneCaptureState(next)
            case .camera: webView.setCameraCaptureState(next)
        }
        devices[device] = now == .live ? .muted : .live
    }

    /// The dot was clicked: the camera and microphone stop.
    package func stopCapture() {
        guard let webView else { return }
        webView.setCameraCaptureState(.none)
        webView.setMicrophoneCaptureState(.none)
        share?.stop(.stopped)
        capture = nil
    }

    package var captureMark: PaneCaptureMark? {
        // Shared into a call: its tab says so, as the call's does.
        if sharedInto > 0 { return .screen }
        return switch capture {
            case .cameraOrMicrophone: .cameraOrMicrophone
            case .screen: .screen
            case nil: nil
        }
    }
}
