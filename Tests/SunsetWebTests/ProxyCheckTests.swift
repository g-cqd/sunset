import Foundation
import Testing

@testable import SunsetWeb

/// n37: the check of the proxy says what it found.
@Suite("Checking the proxy") struct ProxyCheckTests {
    @Test func `answered through the proxy, answered around it, or failed with its reason`() {
        #expect(ProxyCheck.outcome(status: 200, error: nil, viaProxy: true) == .throughProxy)
        #expect(ProxyCheck.outcome(status: 200, error: nil, viaProxy: false) == .notThroughProxy)
        let refused = URLError(.cannotConnectToHost)
        #expect(
            ProxyCheck.outcome(status: nil, error: refused, viaProxy: false) == .failed("The proxy did not answer.")
        )
        #expect(
            ProxyCheck.outcome(status: 407, error: nil, viaProxy: true)
                == .failed("The proxy asks for a password (407).")
        )
        #expect(ProxyCheck.outcome(status: 502, error: nil, viaProxy: true) == .failed("The proxy answered 502."))
    }

    @Test func `the page asked is Apple's captive-network check, over HTTPS`() {
        #expect(ProxyCheck.probe.scheme == "https" && ProxyCheck.probe.host() == "captive.apple.com")
    }
}
