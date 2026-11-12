import Testing

@testable import SunsetConfig

@Suite("The search engines in the file") struct WebEngineSettingsTests {
    @Test func `Google, suggestions on, no http fallback, no engine added by default`() {
        let web = Configuration().web
        #expect(web.engine == "Google" && web.suggestions && !web.httpFallback && web.engines.isEmpty)
    }

    @Test func `an added engine is read; one without %s is an issue and left out`() throws {
        let read = try ConfigurationParser.parse(
            #"""
            { "web": { "engine": "Startpage", "suggestions": false, "httpFallback": true, "engines": [
              { "name": "Startpage", "keyword": "sp", "search": "https://startpage.com/do/search?q=%s" },
              { "name": "Bad", "keyword": "b", "search": "https://bad.example/" }
            ] } }
            """#
        )
        let web = read.configuration.web
        #expect(web.engine == "Startpage" && !web.suggestions && web.httpFallback)
        #expect(web.engines.map(\.keyword) == ["sp"] && web.engines.first?.suggest == nil)
        #expect(read.issues.map(\.path) == ["web.engines[1]"])
    }

    @Test func `the engines are written back as they were read`() throws {
        var configuration = Configuration()
        configuration.web.engines = [
            .init(name: "S", keyword: "s", search: "https://s/?q=%s", suggest: "https://s/ac?q=%s")
        ]
        let text = ConfigurationWriter.literals(for: configuration)["web.engines"] ?? ""
        let read = try ConfigurationParser.parse(#"{ "web": { "engines": "# + text + " } }")
        #expect(read.configuration.web.engines == configuration.web.engines && read.issues.isEmpty)
    }
}
