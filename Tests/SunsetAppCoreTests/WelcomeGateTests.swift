import Testing

@testable import SunsetAppCore

/// The welcome opens by itself once, on a Mac where Sunset was never set up (roadmap 0111 H).
@Suite("When the welcome opens by itself")
struct WelcomeGateTests {
    @Test func `the first launch only: not once seen, not over a configuration, not in the background`() {
        #expect(WelcomeGate.opensByItself(configurationExisted: false, seen: false, background: false))
        #expect(!WelcomeGate.opensByItself(configurationExisted: false, seen: true, background: false))
        #expect(!WelcomeGate.opensByItself(configurationExisted: true, seen: false, background: false))
        #expect(!WelcomeGate.opensByItself(configurationExisted: false, seen: false, background: true))
    }

    @Test func `asked for (a test copy, SUNSET_WELCOME=1), it opens whatever was before`() {
        #expect(WelcomeGate.opensByItself(configurationExisted: true, seen: true, background: true, asked: true))
        #expect(!WelcomeGate.opensByItself(configurationExisted: true, seen: false, background: false, asked: false))
    }
}
