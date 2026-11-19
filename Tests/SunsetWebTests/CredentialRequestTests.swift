import Foundation
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

@Suite("A server that asks for a name and a password") @MainActor struct CredentialRequestTests {
    @Test func `the request names the host; the server's realm is plain text, cut; a clear connection is said`() {
        let request = CredentialRequest(
            host: "intra.example",
            realm: "Staff\n\u{202E}" + String(repeating: "r", count: 300),
            failed: false,
            secure: false
        ) { _ in }
        #expect(request.title == "Sign in to intra.example")
        #expect(request.realm.hasPrefix("Staffrrr") && request.realm.count == CredentialRequest.realmLimit + 1)
        #expect(request.warning == "The password will be sent without encryption.")
        let again = CredentialRequest(host: "a.com", realm: "", failed: true, secure: true) { _ in }
        #expect(again.warning == "That name or password was not accepted." && again.realm.isEmpty)
        #expect(CredentialRequest(host: "a.com", realm: "x", failed: false, secure: true) { _ in }.warning == nil)
    }

    @Test func `it answers once; a page asks one at a time, and closing the page cancels`() async {
        let page = WebContent(url: nil, settings: WebSettings())
        async let first = page.askCredential(host: "a.com", realm: "r", failed: false, secure: true)
        while page.credentialRequest == nil { await Task.yield() }
        #expect(await page.askCredential(host: "b.com", realm: "", failed: false, secure: true) == nil)
        page.credentialRequest?.answer(.init(user: "tide", password: "low"))
        page.credentialRequest?.answer(nil)
        #expect(await first == .init(user: "tide", password: "low") && page.credentialRequest == nil)

        async let second = page.askCredential(host: "a.com", realm: "r", failed: true, secure: true)
        while page.credentialRequest == nil { await Task.yield() }
        page.stop()
        #expect(await second == nil)
    }
}
