import Foundation
import Testing

@testable import SunsetWeb

@Suite("What is typed where an address goes") struct WebInputTests {
    let google = SearchEngine.builtIn[0]
    let all = SearchEngine.builtIn

    func parse(_ text: String) -> WebInput? { WebInput.parse(text, engine: google, engines: all) }

    func address(_ text: String) -> String? {
        if case .address(let url, _) = parse(text) { return url.absoluteString }
        return nil
    }

    @Test func `a host with a dot is tried over https, and marked as guessed`() {
        #expect(parse("example.com/a") == .address(URL(string: "https://example.com/a")!, guessed: true))
        #expect(address("8.8.8.8") == "https://8.8.8.8")
    }

    @Test func `a scheme is kept`() {
        #expect(parse("http://example.com") == .address(URL(string: "http://example.com")!, guessed: false))
        #expect(address("about:blank") == "about:blank")
    }

    @Test func `this machine and the local network go over http at once`() {
        for text in [
            "localhost:3000", "127.0.0.1", "10.1.2.3", "192.168.1.1/admin", "172.20.0.1", "nas.local", "nas:8080",
            "nas/"
        ] {
            #expect(address(text)?.hasPrefix("http://") == true, "\(text)")
        }
        #expect(address("172.32.0.1") == "https://172.32.0.1")
    }

    @Test func `one word, several, a version number or a trailing dot are searched with the default engine`() {
        for text in ["projects", "swift concurrency", "1.2", "end."] {
            #expect(parse(text) == .search(google, words: text), "\(text)")
        }
        #expect(parse("  ") == nil)
    }

    @Test func `a keyword and a space pick the engine`() {
        #expect(parse("ddg swift actors") == .search(all[1], words: "swift actors"))
        #expect(parse("DDG x") == .search(all[1], words: "x"))
        #expect(parse("ddg ") == .search(google, words: "ddg"))
    }

    @Test func `the search address carries the words, encoded`() {
        #expect(google.searchURL("a&b c+d")?.absoluteString == "https://www.google.com/search?q=a%26b%20c%2Bd")
        #expect(all[2].suggestURL("x") == nil)
    }

    @Test func `suggestions are read from the OpenSearch format, nothing from anything else`() {
        let data = Data(#"["swi",["swift","swift ui"],[],{}]"#.utf8)
        #expect(OpenSearchSuggestions.parse(data) == ["swift", "swift ui"])
        #expect(OpenSearchSuggestions.parse(Data(#"{"AS":{}}"#.utf8)).isEmpty)
        #expect(OpenSearchSuggestions.parse(Data("nope".utf8)).isEmpty)
    }

    @Test func `local hosts are told apart`() {
        #expect(LocalHost.isLocal("localhost") && LocalHost.isLocal("[::1]") && LocalHost.isLocal("169.254.1.1"))
        #expect(!LocalHost.isLocal("example.com") && !LocalHost.isLocal("11.0.0.1") && !LocalHost.isLocal("300.1.1.1"))
    }
}
