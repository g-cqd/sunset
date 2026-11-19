import Foundation
import SunsetTestSupport
import Testing

/// A control's explanation comes from help's topics (roadmap 0041 A): a tooltip written where it is used, `.help("…")`, is
/// allowed only for those written before (a button's own name, mostly); the list only shrinks, a new one is a topic.
@Suite("Tooltips from help's topics") struct HelpLiteralTests {
    /// The tooltips written in place before help existed, by file.
    static let allowed: [String: Int] = [
        "SectionPanel+Parts.swift": 1,
        "SiteRuleRow.swift": 1,
        "SidebarNotices.swift": 1, "StorageProblemsBanner.swift": 1, "PrivateMark.swift": 1, "AddressField.swift": 1,
        "NotSecureMark.swift": 1, "DocumentNotices.swift": 2, "EditedMark.swift": 1,
        "SidebarRow+Controls.swift": 1, "ClearNameButton.swift": 1, "SpacesMenuButton.swift": 1, "TabLabel.swift": 1,
        "IconPicker.swift": 1,
        "FavoritesSection.swift": 1
    ]

    @Test func `no tooltip is written in place but those of before; the list only shrinks`() {
        var found: [String: Int] = [:]
        for file in RepositoryFiles.swiftFiles(in: ["Sources"]) {
            let count = file.text.components(separatedBy: ".help(\"").count - 1
            if count > 0 { found[file.name] = count }
        }
        let more = found.filter { $0.value > (Self.allowed[$0.key] ?? 0) }.keys.sorted()
        #expect(more.isEmpty, "use .helpTopic(_:) in: \(more)")
        let fewer = Self.allowed.filter { (found[$0.key] ?? 0) < $0.value }.keys.sorted()
        #expect(fewer.isEmpty, "lower or remove their allowance: \(fewer)")
    }
}
