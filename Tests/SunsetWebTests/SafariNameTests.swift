import Foundation
import Testing

@testable import SunsetWeb

@Suite("A page sees Safari") struct SafariNameTests {
    private func plist(_ value: [String: Any]) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "Info-\(UUID().uuidString).plist")
        try PropertyListSerialization.data(fromPropertyList: value, format: .xml, options: 0).write(to: url)
        return url
    }

    @Test func `Safari's version from its Info.plist, then the token`() throws {
        #expect(
            SafariName.applicationName(infoPlist: try plist(["CFBundleShortVersionString": "26.1"]))
                == "Version/26.1 Safari/605.1.15"
        )
    }

    @Test func `no Safari, or a version that is not one, gives the token alone`() throws {
        #expect(SafariName.applicationName(infoPlist: URL(fileURLWithPath: "/nonexistent")) == "Safari/605.1.15")
        #expect(
            SafariName.applicationName(infoPlist: try plist(["CFBundleShortVersionString": "1) evil"]))
                == "Safari/605.1.15"
        )
    }

    @Test func `the installed Safari is read on this machine`() {
        #expect(SafariName.applicationName().hasPrefix("Version/"))
    }
}
