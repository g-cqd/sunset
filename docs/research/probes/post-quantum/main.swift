// Post-quantum on this Mac, ad hoc signed (2026-11-19): ML-KEM in the Secure Enclave (with and without a biometry access
// control), X-Wing HPKE, ML-DSA; and which TLS key exchange URLSession and a WKWebView page get (Cloudflare's trace).
import CryptoKit
import Foundation
import WebKit

func attempt(_ label: String, _ body: () throws -> String) {
    do { print(label + ":", try body()) } catch { print(label + ": FAILED", error) }
}

attempt("SE ML-KEM-768, made and restored") {
    let key = try SecureEnclave.MLKEM768.PrivateKey()
    let restored = try SecureEnclave.MLKEM768.PrivateKey(dataRepresentation: key.dataRepresentation)
    let sealed = try key.publicKey.encapsulate()
    let opened = try restored.decapsulate(sealed.encapsulated)
    return
        "blob \(key.dataRepresentation.count) B, ciphertext \(sealed.encapsulated.count) B, secrets equal \(opened == sealed.sharedSecret)"
}
attempt("SE ML-KEM-1024 with .biometryCurrentSet") {
    var error: Unmanaged<CFError>?
    guard
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage, .biometryCurrentSet],
            &error
        )
    else { return "no access control" }
    let key = try SecureEnclave.MLKEM1024.PrivateKey(accessControl: access)
    return "made, blob \(key.dataRepresentation.count) B (decapsulating asks Touch ID: not exercised)"
}
attempt("X-Wing HPKE (ML-KEM-768 + X25519, SHA-256, AES-GCM-256)") {
    let recipient = try XWingMLKEM768X25519.PrivateKey()
    let suite = HPKE.Ciphersuite.XWingMLKEM768X25519_SHA256_AES_GCM_256
    var sender = try HPKE.Sender(recipientKey: recipient.publicKey, ciphersuite: suite, info: Data("sunset".utf8))
    let box = try sender.seal(Data("vault key".utf8))
    var receiver = try HPKE.Recipient(
        privateKey: recipient,
        ciphersuite: suite,
        info: Data("sunset".utf8),
        encapsulatedKey: sender.encapsulatedKey
    )
    return
        "encapsulated \(sender.encapsulatedKey.count) B, opened \(String(decoding: try receiver.open(box), as: UTF8.self))"
}
attempt("SE ML-DSA-65 signature") {
    let key = try SecureEnclave.MLDSA65.PrivateKey()
    let signature = try key.signature(for: Data("segment".utf8))
    return
        "signature \(signature.count) B, valid \(key.publicKey.isValidSignature(signature, for: Data("segment".utf8)))"
}

guard let trace = URL(string: "https://www.cloudflare.com/cdn-cgi/trace") else { exit(1) }
let semaphore = DispatchSemaphore(value: 0)
URLSession.shared
    .dataTask(with: trace) { data, _, error in
        let text = data.map { String(decoding: $0, as: UTF8.self) } ?? "\(String(describing: error))"
        print(
            "URLSession:",
            text.split(separator: "\n").filter { $0.hasPrefix("kex=") || $0.hasPrefix("tls=") || $0.hasPrefix("http=") }
                .joined(separator: " ")
        )
        semaphore.signal()
    }
    .resume()
semaphore.wait()

@MainActor final class Page: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.body.innerText") { result, _ in
            let text = result as? String ?? ""
            print(
                "WKWebView:",
                text.split(separator: "\n")
                    .filter { $0.hasPrefix("kex=") || $0.hasPrefix("tls=") || $0.hasPrefix("http=") }
                    .joined(separator: " ")
            )
            exit(0)
        }
    }
}
MainActor.assumeIsolated {
    let page = Page()
    let view = WKWebView()
    view.navigationDelegate = page
    view.load(URLRequest(url: trace))
    withExtendedLifetime((page, view)) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 20)) }
}
