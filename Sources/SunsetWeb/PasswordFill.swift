import Foundation
import WebKit

/// Filling and saving in pages (roadmap 0094, ADR-0094): a script in Sunset's own world, in the main frame and in each
/// frame of the page's origin all the way up, tells when a sign-in field takes or leaves the keyboard, and where it is;
/// and, unless the page is private, a password sent with its username. The page's own scripts cannot post to it, see it, or call it. Filling is the app's, on the person's act
/// (`WebContent.fill`).
@MainActor
final class PasswordFill: PageScriptHandler, WKScriptMessageHandler {
    /// Where the fields are told: the app's vault. None: nothing is told.
    static weak var host: (any PasswordFillHost)?

    static let name = "sunsetPasswordFill"

    static func install(on configuration: WKWebViewConfiguration, for page: WebContent, privately: Bool) {
        configuration.userContentController.addClientScript(
            PasswordFillScript.watch(saving: !privately, handler: name),
            handler: PasswordFill(page: page),
            name: name
        )
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let page = content, let host = page.passwordFillHost ?? Self.host,
            let body = message.body as? [String: Any], let origin = Self.origin(of: message.frameInfo),
            message.frameInfo.isMainFrame || origin == page.webView?.url.flatMap(Self.origin(of:))
        else { return }
        switch body["kind"] as? String {
            case "focus":
                // A page out of every window (a background tab, one being closed) is not on screen: nothing is offered
                // for it (n144).
                guard Self.isOnScreen(page),
                    let role = (body["role"] as? String).flatMap(LoginField.Role.init(rawValue:))
                else { return }
                let field = LoginField(
                    role: role,
                    frame: Self.frame(body, in: page),
                    origin: origin,
                    rules: body["rules"] as? String
                )
                page.fillFrame = message.frameInfo
                host.loginField(focused: field, in: page)
            case "blur":
                host.loginFieldBlurred(in: page)
            case "form":
                // As a focus, only for a page on screen (n144): a tab loaded behind is filled by the person's click.
                guard Self.isOnScreen(page) else { return }
                page.formFrame = message.frameInfo
                let field = LoginField(role: .password, frame: Self.frame(body, in: page), origin: origin, rules: nil)
                host.loginFormShown(field, in: page)
            case "sent":
                guard let password = body["password"] as? String, !password.isEmpty else { return }
                host.loginSent(
                    SentLogin(
                        origin: origin,
                        username: body["username"] as? String ?? "",
                        password: password,
                        frame: Self.frame(body, in: page)
                    ),
                    in: page
                )
            default:
                return
        }
    }

    /// Whether the page's view is in a window and not hidden.
    private static func isOnScreen(_ page: WebContent) -> Bool {
        guard let view = page.webView, view.window != nil else { return false }
        return !view.isHiddenOrHasHiddenAncestor
    }

    /// An address's origin, as `origin(of:)` writes a frame's.
    private static func origin(of url: URL) -> URL? {
        guard let scheme = url.scheme, let host = url.host(), !host.isEmpty else { return nil }
        let port = url.port.map { ":\($0)" } ?? ""
        return URL(string: "\(scheme)://\(host)\(port)")
    }

    /// The frame's origin, as WebKit says it.
    private static func origin(of frame: WKFrameInfo) -> URL? {
        let origin = frame.securityOrigin
        guard !origin.host.isEmpty else { return nil }
        let port = origin.port == 0 ? "" : ":\(origin.port)"
        return URL(string: "\(origin.protocol)://\(origin.host)\(port)")
    }

    /// A field's rect the script gave (CSS pixels of the page's viewport), in the page's view.
    private static func frame(_ body: [String: Any], in page: WebContent) -> CGRect {
        let zoom = page.webView?.pageZoom ?? 1
        return CGRect(
            x: number(body["x"]) * zoom,
            y: number(body["y"]) * zoom,
            width: number(body["width"]) * zoom,
            height: number(body["height"]) * zoom
        )
    }

    private static func number(_ value: Any?) -> Double {
        (value as? NSNumber)?.doubleValue ?? 0
    }
}
