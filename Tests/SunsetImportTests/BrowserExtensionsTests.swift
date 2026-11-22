import Foundation
import Testing

@testable import SunsetImport

/// Other browsers' extensions: named, with the store page Sunset installs them from.
@Suite("Other browsers' extensions")
struct BrowserExtensionsTests {
    private let blocker = "cjpalhdlnbpafiamejdnhcphjbkeiagm"
    private let notes = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

    private func write(_ text: String, to path: String, in folder: URL) throws {
        let file = folder.appending(path: path)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: file)
    }

    @Test func `Chromium: the newest version's name, a localized one looked up, and its Web Store page`() throws {
        let profile = FileManager.default.temporaryDirectory.appending(path: "chromium-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: profile) }
        try write(
            #"{"name": "uBlock Origin", "version": "1.60.0"}"#,
            to: "Extensions/\(blocker)/1.60.0_0/manifest.json",
            in: profile
        )
        try write(
            #"{"name": "uBlock Origin (old)", "version": "1.9.0"}"#,
            to: "Extensions/\(blocker)/1.9.0_0/manifest.json",
            in: profile
        )
        try write(
            #"{"name": "__MSG_appName__", "default_locale": "en"}"#,
            to: "Extensions/\(notes)/2.0_0/manifest.json",
            in: profile
        )
        try write(
            #"{"appName": {"message": "Notes"}}"#,
            to: "Extensions/\(notes)/2.0_0/_locales/en/messages.json",
            in: profile
        )
        try write("{}", to: "Extensions/Temp/manifest.json", in: profile)
        // Chrome Web Store Payments: Chrome installs it; nobody chose it (seen offered on screen).
        try write(
            #"{"name": "Chrome Web Store Payments"}"#,
            to: "Extensions/nmmhkkegccagdldgiimedpiccmgmieda/1.0.0.6_0/manifest.json",
            in: profile
        )
        #expect(
            ChromiumExtensions.read(profile: profile) == [
                BrowserExtension(
                    id: notes,
                    name: "Notes",
                    store: URL(string: "https://chromewebstore.google.com/detail/\(notes)")
                ),
                BrowserExtension(
                    id: blocker,
                    name: "uBlock Origin",
                    store: URL(string: "https://chromewebstore.google.com/detail/\(blocker)")
                )
            ]
        )
        #expect(ChromiumExtensions.read(profile: profile.appending(path: "missing")).isEmpty)
    }

    @Test
    func
        `Firefox: the person's extensions with their add-ons page; built in, system, themes and dictionaries left out`()
        throws
    {
        let data = Data(
            """
            {"schemaVersion": 36, "addons": [
              {"id": "uBlock0@raymondhill.net", "type": "extension", "location": "app-profile", "active": true,
               "userDisabled": false, "defaultLocale": {"name": "uBlock Origin"}},
              {"id": "{446900e4-71c2-419f-a6a7-df9c091e268b}", "type": "extension", "location": "app-profile",
               "userDisabled": true, "defaultLocale": {"name": "Bitwarden"}},
              {"id": "formautofill@mozilla.org", "type": "extension", "location": "app-builtin", "defaultLocale": {"name": "Form Autofill"}},
              {"id": "screenshots@mozilla.org", "type": "extension", "location": "app-system-defaults", "defaultLocale": {"name": "Screenshots"}},
              {"id": "firefox-compact-dark@mozilla.org", "type": "theme", "location": "app-builtin", "defaultLocale": {"name": "Dark"}},
              {"id": "fr-dicollecte@dictionaries.addons.mozilla.org", "type": "dictionary", "location": "app-profile", "defaultLocale": {"name": "French"}}
            ]}
            """
            .utf8
        )
        #expect(
            try FirefoxExtensions.read(data) == [
                BrowserExtension(
                    id: "uBlock0@raymondhill.net",
                    name: "uBlock Origin",
                    store: URL(string: "https://addons.mozilla.org/firefox/addon/uBlock0@raymondhill.net/")
                ),
                BrowserExtension(
                    id: "{446900e4-71c2-419f-a6a7-df9c091e268b}",
                    name: "Bitwarden",
                    store: URL(
                        string: "https://addons.mozilla.org/firefox/addon/%7B446900e4-71c2-419f-a6a7-df9c091e268b%7D/"
                    ),
                    isEnabled: false
                )
            ]
        )
        #expect(throws: DecodingError.self) { try FirefoxExtensions.read(Data("[]".utf8)) }
    }
}
