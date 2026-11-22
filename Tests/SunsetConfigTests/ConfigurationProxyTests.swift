import Testing

@testable import SunsetConfig

/// `web.proxy`, an http or socks5 address with a port, or nothing; anything else is said and left out.
@Suite("A proxy for the pages: the setting")
struct ConfigurationProxyTests {
    @Test func `none by default; http and socks5 with a port; others said`() throws {
        #expect(try ConfigurationParser.parse("{}").configuration.web.proxy.isEmpty)
        let socks = try ConfigurationParser.parse(#"{ "web": { "proxy": "socks5://127.0.0.1:1080" } }"#)
        #expect(socks.issues.isEmpty && socks.configuration.web.proxy == "socks5://127.0.0.1:1080")
        let back = try ConfigurationParser.parse(ConfigurationWriter.text(for: socks.configuration))
        #expect(back.issues.isEmpty && back.configuration.web.proxy == "socks5://127.0.0.1:1080")
        for bad in ["https://p.example:443", "http://p.example", "p.example:80"] {
            let read = try ConfigurationParser.parse(#"{ "web": { "proxy": "\#(bad)" } }"#)
            #expect(read.issues.count == 1 && read.configuration.web.proxy.isEmpty, "\(bad)")
        }
        #expect(SettingsSection.topic("web.proxy")?.topic.options.map(\.id) == ["web.proxy", "web.proxyCheck"])
    }
}
