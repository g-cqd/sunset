import Foundation
import WebKit

/// Filling and saving in pages (roadmap 0094, ADR-0094): a script in Sunset's own world, in the main frame, tells when a
/// sign-in field takes or leaves the keyboard, and where it is; and, unless the page is private, a password sent with its
/// username. The page's own scripts cannot post to it, see it, or call it. Filling is the app's, on the person's act
/// (`WebContent.fill`).
@MainActor
final class PasswordFill: PageScriptHandler, WKScriptMessageHandler {
    /// Where the fields are told: the app's vault. None: nothing is told.
    static weak var host: (any PasswordFillHost)?

    static let name = "sunsetPasswordFill"

    static func install(on configuration: WKWebViewConfiguration, for page: WebContent, privately: Bool) {
        let controller = configuration.userContentController
        controller.addUserScript(
            WKUserScript(
                source: PasswordFillScript.watch(saving: !privately, handler: name),
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true,
                in: .defaultClient
            )
        )
        controller.add(PasswordFill(page: page), contentWorld: .defaultClient, name: name)
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, let page = content, let host = Self.host,
            let body = message.body as? [String: Any], let origin = Self.origin(of: message.frameInfo)
        else { return }
        switch body["kind"] as? String {
            case "focus":
                guard let role = (body["role"] as? String).flatMap(LoginField.Role.init(rawValue:)) else { return }
                host.loginField(
                    focused: LoginField(role: role, frame: Self.frame(body, in: page), origin: origin),
                    in: page
                )
            case "blur":
                host.loginFieldBlurred(in: page)
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
