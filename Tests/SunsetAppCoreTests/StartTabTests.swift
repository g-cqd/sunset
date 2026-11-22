import Foundation
import SunsetConfig
import Testing

@testable import SunsetAppCore

/// What opens when Sunset (or a window on an empty Space) starts with no tab.
@Suite("What opens with no tab")
struct StartTabTests {
    private func tabs(_ start: Configuration.Tabs.Start, address: String = "", file: String = "") -> Configuration.Tabs
    {
        var tabs = Configuration.Tabs()
        tabs.start = start
        tabs.startAddress = address
        tabs.startFile = file
        return tabs
    }

    @Test func `nothing by default; a kind of tab, a new document`() {
        #expect(StartTab.resolve(Configuration.Tabs()) == .nothing)
        #expect(StartTab.resolve(tabs(.terminal)) == .terminal)
        #expect(StartTab.resolve(tabs(.web)) == .page(nil))
        #expect(StartTab.resolve(tabs(.newDocument)) == .newDocument)
    }

    @Test
    func `an address as typed in the address field; a file by its path, ~ expanded; nothing when either is empty`() {
        #expect(StartTab.resolve(tabs(.address, address: "example.com")) == .page(URL(string: "https://example.com")))
        #expect(StartTab.resolve(tabs(.address, address: "https://a.test/x")) == .page(URL(string: "https://a.test/x")))
        #expect(StartTab.resolve(tabs(.address, address: "  ")) == .nothing)
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        #expect(StartTab.resolve(tabs(.file, file: "~/n.md")) == .file(home + "/n.md"))
        #expect(StartTab.resolve(tabs(.file, file: "")) == .nothing)
    }
}
