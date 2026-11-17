import Testing

@testable import SunsetConfig

/// `web.agent` (roadmap 0022, W-a; the owner, 2026-11-17: "a possibility to set it to always appear as chrome"): the
/// browser every site with no rule of its own is shown. Safari is Sunset as it is.
@Suite("The browser sites are shown, in the settings")
struct WebAgentSettingsTests {
    @Test func `Safari by default; another browser when the file names one; written back; an unknown one is said`()
        throws
    {
        #expect(Configuration().web.agent == .safari)
        let set = try ConfigurationParser.parse(#"{ "web": { "agent": "chrome" } }"#)
        #expect(set.issues.isEmpty && set.configuration.web.agent == .chrome)
        let again = try ConfigurationParser.parse(ConfigurationWriter.text(for: set.configuration))
        #expect(again.configuration.web.agent == .chrome)
        let bad = try ConfigurationParser.parse(#"{ "web": { "agent": "netscape" } }"#)
        #expect(bad.issues.map(\.path) == ["web.agent"] && bad.configuration.web.agent == .safari)
        #expect(Configuration.Web.Agent.allCases.map(\.rawValue) == ["safari", "chrome", "edge", "firefox"])
        // The second rung is on unless the file turns it off.
        #expect(Configuration().web.agentScripts)
        let off = try ConfigurationParser.parse(#"{ "web": { "agentScripts": false } }"#)
        #expect(off.issues.isEmpty && !off.configuration.web.agentScripts)
        #expect(
            try !ConfigurationParser.parse(ConfigurationWriter.text(for: off.configuration)).configuration.web
                .agentScripts
        )
    }
}
