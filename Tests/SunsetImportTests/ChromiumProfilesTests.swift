import Foundation
import Testing

@testable import SunsetImport

/// Chromium's `Local State`: its profiles, each a folder and the person's name for it.
@Suite("Chromium's profiles")
struct ChromiumProfilesTests {
    @Test func `the profiles in the order the browser shows them; the guest and system profiles are not the person's`()
        throws
    {
        let data = Data(
            """
            {"profile": {
                "profiles_order": ["Profile 2", "Default"],
                "info_cache": {
                    "Default": {"name": "Personal", "is_using_default_name": false},
                    "Profile 2": {"name": "Work"},
                    "Guest Profile": {"name": "Guest", "is_guest": true},
                    "System Profile": {"name": "System"}
                }
            }}
            """
            .utf8
        )
        #expect(
            try ChromiumProfiles.read(data) == [
                BrowserProfile(folder: "Profile 2", name: "Work"), BrowserProfile(folder: "Default", name: "Personal")
            ]
        )
    }

    @Test func `without an order, by folder; without a name, the folder's`() throws {
        let data = Data(#"{"profile": {"info_cache": {"Profile 1": {}, "Default": {"name": " "}}}}"#.utf8)
        #expect(
            try ChromiumProfiles.read(data) == [
                BrowserProfile(folder: "Default", name: "Default"),
                BrowserProfile(folder: "Profile 1", name: "Profile 1")
            ]
        )
    }

    @Test func `a file that is not Chromium's is refused; one without profiles has none`() throws {
        #expect(throws: DecodingError.self) { try ChromiumProfiles.read(Data("[]".utf8)) }
        #expect(try ChromiumProfiles.read(Data("{}".utf8)).isEmpty)
    }
}
