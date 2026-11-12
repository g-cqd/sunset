import SunsetPrivate
import WebKit

/// The permission questions WebKit asks of a page (web step g): the camera and microphone, location (public API), screen sharing and notifications
/// (WebKit's private questions, `WebPermissionHooks`), pop-ups opened without a click.
extension WebCoordinator {
    func webView(
        _ webView: WKWebView,
        decideMediaCapturePermissionsFor origin: WKSecurityOrigin,
        initiatedBy frame: WKFrameInfo,
        type: WKMediaCaptureType
    ) async -> WKPermissionDecision {
        let wanted: [SitePermission] =
            switch type {
                case .camera: [.camera]
                case .microphone: [.microphone]
                default: [.camera, .microphone]
            }
        guard let content else { return .deny }
        return await content.ask(wanted, host: origin.host) ? .grant : .deny
    }

    func webView(
        _ webView: WKWebView,
        requestGeolocationPermissionFor origin: WKSecurityOrigin,
        initiatedBy frame: WKFrameInfo
    ) async -> WKPermissionDecision {
        guard let content else { return .deny }
        return await content.ask([.location], host: origin.host) ? .grant : .deny
    }

    /// The private questions, added to this class once.
    static func installPrivateQuestions() {
        WebPermissionHooks.install(
            on: WebCoordinator.self,
            screen: { delegate, _, origin, decide in
                answer(delegate, origin, [.screen], decide)
            },
            notifications: { delegate, _, origin, decide in
                answer(delegate, origin, [.notifications], decide)
            }
        )
    }

    private static func answer(
        _ delegate: AnyObject,
        _ origin: AnyObject,
        _ wanted: [SitePermission],
        _ decide: @escaping (Bool) -> Void
    ) {
        guard let coordinator = delegate as? WebCoordinator, let content = coordinator.content,
            let host = (origin as? WKSecurityOrigin)?.host
        else { return decide(false) }
        Task { @MainActor in
            let granted = await content.ask(wanted, host: host)
            if granted, wanted == [.screen] { content.capture = .screen }
            decide(granted)
        }
    }

    /// A pop-up opened without a click: by the site's answer; asked, it opens (as a tab after the page) only once allowed.
    func popupAllowed(_ action: WKNavigationAction, from webView: WKWebView) -> Bool {
        if WebPermissionHooks.isUserInitiated(action) ?? true { return true }
        guard let content, let host = webView.url?.host() else { return false }
        switch SitePermissions.shared.answer(.popups, for: host) {
            case .allow: return true
            case .deny: return false
            case .ask:
                let address = action.request.url
                Task { @MainActor in
                    if await content.ask([.popups], host: host), let address {
                        content.onOpen(WebContent(url: address, settings: content.settings), .tabAfter)
                    }
                }
                return false
        }
    }
}
