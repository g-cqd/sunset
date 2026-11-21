import Testing

@testable import SunsetConfig

/// The welcome's choices (roadmap 0111 H): its pages, and the security models it offers as settings.
@Suite("The welcome")
struct WelcomeTests {
    @Test func `what Sunset ships with is the balanced model`() {
        #expect(SecurityPreset.matching(Configuration.Web()) == .balanced)
    }

    @Test func `each model sets its settings, and is recognised from them`() {
        for preset in SecurityPreset.allCases {
            var web = Configuration.Web()
            preset.apply(to: &web)
            #expect(SecurityPreset.matching(web) == preset, "\(preset)")
        }
        var strict = Configuration.Web()
        SecurityPreset.strict.apply(to: &strict)
        #expect(
            strict.httpsUpgrade == .only && strict.hardening == .noJIT && strict.globalPrivacyControl == .always
                && strict.blocking
        )
        var compatible = Configuration.Web()
        SecurityPreset.compatible.apply(to: &compatible)
        #expect(compatible.httpsUpgrade == .fallback && compatible.hardening == .off && !compatible.blocking)
    }

    @Test func `settings changed by hand match no model`() {
        var web = Configuration.Web()
        web.hardening = .noJIT
        #expect(SecurityPreset.matching(web) == nil)
    }

    @Test func `the pages follow what is on: no browser questions without web pages`() {
        #expect(WelcomeStep.steps(for: .init()) == WelcomeStep.allCases)
        #expect(
            WelcomeStep.allCases == [.hello, .features, .security, .defaultBrowser, .search, .start, .importing, .done]
        )
        #expect(
            WelcomeStep.steps(for: .init(terminal: true, web: false, documents: true)) == [
                .hello, .features, .start, .done
            ]
        )
    }
}
