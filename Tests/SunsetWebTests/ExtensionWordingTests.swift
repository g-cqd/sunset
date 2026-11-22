import Testing

@testable import SunsetWebModel

/// What the install prompt says an extension may do, one line per thing it asks, in plain words (granted at install,
/// all or nothing, so the person must read what).
@Suite("What an extension asks, said plainly")
struct ExtensionWordingTests {
    @Test func `sites: every site, one site, its subdomains; permissions by what they let it do`() {
        #expect(ExtensionWording.site("<all_urls>") == "Read and change every website")
        #expect(ExtensionWording.site("*://*/*") == "Read and change every website")
        #expect(ExtensionWording.site("https://a.example/*") == "Read and change pages on a.example")
        #expect(ExtensionWording.site("*://*.a.example/*") == "Read and change pages on a.example and its subdomains")
        #expect(ExtensionWording.permission("tabs") == "See your open tabs' titles and addresses")
        #expect(ExtensionWording.permission("cookies") == "Read and change cookies")
        #expect(ExtensionWording.permission("storage") == nil, "nothing the person must weigh")
        #expect(ExtensionWording.permission("someNewThing") == "Use “someNewThing”", "an unknown one is still listed")
    }

    @Test func `the lines: sites first, every site above the others, then permissions, each once`() {
        let lines = ExtensionWording.lines(
            permissions: ["storage", "tabs", "cookies", "tabs"],
            sites: ["https://a.example/*", "<all_urls>"]
        )
        #expect(
            lines == [
                "Read and change every website", "Read and change pages on a.example",
                "Read and change cookies", "See your open tabs' titles and addresses"
            ]
        )
    }

    /// What blocking `webRequest` lets an extension do is said in words at install, its headers included.
    @Test func `webRequest is worded as what it lets the extension do`() {
        #expect(ExtensionWording.permission("webRequest") == "See the requests pages make")
        #expect(
            ExtensionWording.permission("webRequestBlocking")
                == "Block, redirect or change requests, and a page's security headers"
        )
    }
}
