import Foundation
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// A probe, not a test of the suite: run with SUNSET_PROXY_PROBE=1 and a CONNECT proxy on 127.0.0.1:18080.
@Suite("Checking a real proxy", .enabled(if: ProcessInfo.processInfo.environment["SUNSET_PROXY_PROBE"] == "1"))
struct ProxyCheckProbe {
    @Test func `through a proxy that answers, and one that does not`() async {
        let up = await ProxyCheck.run(WebProxy("http://127.0.0.1:18080"))
        print("PROBE up:", up)
        #expect(up == .throughProxy)
        let down = await ProxyCheck.run(WebProxy("http://127.0.0.1:18089"))
        print("PROBE down:", down)
        #expect(down == .failed("The proxy did not answer."))
    }
}
