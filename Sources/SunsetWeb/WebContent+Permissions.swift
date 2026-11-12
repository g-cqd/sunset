import Foundation
package import SwiftUI
import WebKit

/// A page's questions to the person (web step g): answered from what the site was given, else asked in the panel, one at a time.
extension WebContent {
    /// Whether the page may have all of `permissions`: a kept Deny refuses at once, a kept Allow grants at once, else the panel asks. Without
    /// Sunset.app's identity, what macOS must also allow is refused, the panel saying why.
    func ask(_ permissions: [SitePermission], host: String) async -> Bool {
        let store = SitePermissions.shared
        let answers = permissions.map { store.answer($0, for: host) }
        if answers.contains(.deny) { return false }
        let unavailable = !settings.hasAppIdentity && permissions.contains(where: \.needsAppIdentity)
        if answers.allSatisfy({ $0 == .allow }), !unavailable { return true }
        // One question at a time: a newer one waits for the one shown.
        while permissionRequest != nil { try? await Task.sleep(for: .milliseconds(200)) }
        return await withCheckedContinuation { continuation in
            permissionRequest = PermissionRequest(permissions: permissions, host: host, unavailable: unavailable) {
                [weak self] granted in
                self?.permissionRequest = nil
                continuation.resume(returning: granted)
            }
        }
    }

    /// The site of the page, for its answers.
    var siteHost: String? { url?.host() ?? webView?.url?.host() }

    func captureChanged(_ view: WKWebView) {
        let active = view.cameraCaptureState != .none || view.microphoneCaptureState != .none
        if active { capture = .cameraOrMicrophone } else if capture == .cameraOrMicrophone { capture = nil }
    }

    /// The dot was clicked: the camera and microphone stop.
    package func stopCapture() {
        guard let webView else { return }
        webView.setCameraCaptureState(.none)
        webView.setMicrophoneCaptureState(.none)
        capture = nil
    }

    package var captureDot: Color? {
        switch capture {
            case .cameraOrMicrophone: .red
            case .screen: .orange
            case nil: nil
        }
    }
}
