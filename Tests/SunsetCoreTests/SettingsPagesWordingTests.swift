import Foundation
import SunsetTestSupport
import Testing

/// The Settings pages built by hand (Websites, Profiles, Storage, the custom rows) follow the wording rules of
/// docs/design/0005 as the generated options do (roadmap 0040 D): a control's name is not started by an article, not a
/// fragment its values finish, and spelled as macOS spells.
@Suite("Settings' hand-built pages' wording") struct SettingsPagesWordingTests {
    /// The files of the pages Settings draw by hand.
    static let pages = [
        "FeaturesSettings.swift", "ProfilesSettings.swift", "SettingsCustomRow.swift", "SiteAgentsSettings.swift",
        "StorageSettings.swift", "WebsitesSettings.swift", "EngineList.swift", "SitesSettings.swift",
        "BlockingListsSettings.swift", "SettingsRow.swift"
    ]

    /// The names given to controls: the first string of a `Toggle`, `Picker`, `Label`, `Section`, `LabeledContent`,
    /// `Button`, `TextField`, `SettingsLabel` or an engine's `field`, by file.
    static var names: [(file: String, name: String)] {
        let control =
            #"\b(Toggle|Picker|Label|Section|LabeledContent|Button|TextField|SettingsLabel|field)\("([^"\\]+)""#
        let pattern = try? NSRegularExpression(pattern: control)
        var found: [(String, String)] = []
        for file in RepositoryFiles.swiftFiles(in: ["Sources/SunsetApp"]) where pages.contains(file.name) {
            let text = file.text as NSString
            for match in pattern?.matches(in: file.text, range: NSRange(location: 0, length: text.length)) ?? [] {
                found.append((file.name, text.substring(with: match.range(at: 2))))
            }
        }
        return found
    }

    @Test func `every page is read`() {
        let read = Set(RepositoryFiles.swiftFiles(in: ["Sources/SunsetApp"]).map(\.name))
        #expect(Set(Self.pages).isSubset(of: read))
        #expect(Self.names.count > 10)
    }

    @Test func `no name starts with an article, nor is a fragment its values finish`() {
        let endings = [" the", " in", " to", " at", " for", " goes", " shows", " is", " with", " see", " as"]
        let found = Self.names.filter { item in
            item.name.range(of: #"^(The|A|An) "#, options: .regularExpression) != nil
                || endings.contains { item.name.hasSuffix($0) }
        }
        #expect(found.isEmpty, "\(found.map { "\($0.file): \($0.name)" })")
    }

    @Test func `one spelling, the system's`() {
        let british = #"(?i)\b(colour|favourite|grey|centre|behaviour)"#
        let found = Self.names.filter { $0.name.range(of: british, options: .regularExpression) != nil }
        #expect(found.isEmpty, "\(found.map { "\($0.file): \($0.name)" })")
    }
}
