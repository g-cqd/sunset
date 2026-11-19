// In a bare WKWebView on a secure origin: which payment and credential APIs a page sees, by flag and with or without a user
// script (WebKit is said to turn Apple Pay off once an app injects script); 2026-11-19.
import AppKit
import WebKit

@MainActor func view(flags: [String], script: Bool) -> WKWebView {
    let c = WKWebViewConfiguration()
    let t = type(of: c.preferences) as AnyObject as? NSObject ?? NSObject()
    let features = t.value(forKey: "_features") as? [NSObject] ?? []
    let setter = NSSelectorFromString("_setEnabled:forFeature:")
    typealias Setter = @convention(c) (NSObject, Selector, Bool, NSObject) -> Void
    let call = unsafeBitCast(c.preferences.method(for: setter), to: Setter.self)
    for f in features where flags.contains(f.value(forKey: "key") as? String ?? "") {
        call(c.preferences, setter, true, f)
    }
    if script {
        c.userContentController.addUserScript(
            WKUserScript(source: "window.x = 1", injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )
    }
    return WKWebView(frame: .init(x: 0, y: 0, width: 300, height: 200), configuration: c)
}

let probe = """
    const has = (n) => n in window ? "yes" : "no";
    const out = { ApplePaySession: has("ApplePaySession"), PaymentRequest: has("PaymentRequest"), DigitalCredential: has("DigitalCredential"),
      PublicKeyCredential: has("PublicKeyCredential"), PasswordCredential: has("PasswordCredential"), IdentityCredential: has("IdentityCredential"),
      OTPCredential: has("OTPCredential") };
    try { out.canMakePayments = String(ApplePaySession.canMakePayments()); } catch (e) { out.canMakePayments = e.name + ": " + e.message; }
    try { out.supportsVersion = String(ApplePaySession.supportsVersion(14)); } catch (e) { out.supportsVersion = e.name; }
    try { out.uvpa = String(await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()); } catch (e) { out.uvpa = e.name; }
    try { out.conditional = String(await PublicKeyCredential.isConditionalMediationAvailable()); } catch (e) { out.conditional = e.name; }
    try { out.capabilities = JSON.stringify(await PublicKeyCredential.getClientCapabilities()); } catch (e) { out.capabilities = e.name; }
    try {
      await navigator.credentials.create({ publicKey: { rp: { name: "x" }, user: { id: new Uint8Array(8), name: "a", displayName: "a" },
        challenge: new Uint8Array(16), pubKeyCredParams: [{ type: "public-key", alg: -7 }], timeout: 2000 } });
      out.create = "made";
    } catch (e) { out.create = e.name + ": " + e.message; }
    try { new PaymentRequest([{ supportedMethods: "https://apple.com/apple-pay", data: { version: 3, merchantIdentifier: "m", merchantCapabilities: ["supports3DS"], supportedNetworks: ["visa"], countryCode: "US" } }], { total: { label: "t", amount: { currency: "USD", value: "1" } } }); out.pr = "made"; } catch (e) { out.pr = e.name + ": " + e.message; }
    return JSON.stringify(out);
    """

@MainActor final class Run: NSObject, WKNavigationDelegate {
    var next: (() -> Void)?
    func webView(_ w: WKWebView, didFinish n: WKNavigation!) { next?() }
}

MainActor.assumeIsolated {
    let cases: [(String, [String], Bool)] = [
        ("defaults", [], false),
        ("ApplePay+DigitalCredentials", ["ApplePayEnabled", "DigitalCredentialsEnabled"], false),
        ("ApplePay+DigitalCredentials, a user script", ["ApplePayEnabled", "DigitalCredentialsEnabled"], true)
    ]
    let run = Run()
    var views: [WKWebView] = []
    @MainActor func go(_ i: Int) {
        guard i < cases.count else { exit(0) }
        let (label, flags, script) = cases[i]
        let w = view(flags: flags, script: script)
        views.append(w)
        w.navigationDelegate = run
        run.next = {
            w.callAsyncJavaScript(probe, arguments: [:], in: nil, in: .page) { @MainActor r in
                print(label, "->", (try? r.get()) ?? "\(r)")
                go(i + 1)
            }
        }
        w.loadHTMLString("<p>pay</p>", baseURL: URL(string: "https://shop.example/"))
    }
    go(0)
    NSApplication.shared.run()
}
