import Testing

@testable import SunsetConfig

/// The sections and topics of Settings (roadmap 0032; the review of 2026-11-15, 5.3, with the owner's changes of the same day).
@Suite("The sections and topics of Settings") struct SettingsSectionTests {
    let sections = SettingsSection.all

    func options(_ topic: String) -> [String] { SettingsSection.topic(topic)?.topic.options.map(\.id) ?? [] }

    @Test func `seven sections, each with its topics, and no Layout among them`() {
        #expect(
            sections.map(\.title) == [
                "General", "Appearance", "Window", "Tabs and sidebar", "Terminal", "Web", "Privacy and security"
            ]
        )
        #expect(sections.allSatisfy { !$0.symbol.isEmpty && !$0.topics.isEmpty })
        let topics = sections.flatMap(\.topics)
        #expect(Set(topics.map(\.id)).count == topics.count, "a topic's identifier is used twice")
        #expect(topics.allSatisfy { !$0.options.isEmpty && !$0.title.isEmpty }, "a topic with nothing in it")
        #expect(topics.allSatisfy { topic in topic.options.allSatisfy { $0.topic == topic.id } })
    }

    @Test func `every option is in one topic, and the options are the sections'`() {
        let placed = sections.flatMap(\.topics).flatMap(\.options).map(\.id)
        #expect(placed == SettingsOption.all.map(\.id))
        #expect(Set(placed).count == placed.count, "an option is in two topics")
    }

    @Test func `the cursor has its colour, with its shape and its blinking (the owner)`() {
        #expect(options("terminal.cursor") == ["cursor.shape", "colors.cursor", "cursor.blink", "cursor.blinkTimeout"])
        #expect(!options("appearance.theme").contains("colors.cursor"))
    }

    @Test func `what a program may copy is under Privacy and security, with what the web keeps (the owner)`() {
        #expect(options("privacy.programs") == ["terminal.clipboardWrite"])
        #expect(
            options("privacy.browsing") == [
                "web.historyKeep", "web.clearHistoryOnQuit", "web.keep.siteData", "web.keep.cache", "web.keep.traces",
                "web.privateWindowShares"
            ]
        )
    }

    /// The owner's note n35 (2026-11-18): "remove all the padding/spacing/margin settings from the settings because now … we
    /// figured them out". They stay in the file; Settings shows the terminal text's own padding and the floating sidebar's
    /// behaviour only.
    @Test func `no padding, spacing, margin or radius measure in Settings but the terminal text's padding`() {
        let all = SettingsSection.all.flatMap(\.topics).flatMap { $0.first + $0.further }.map(\.id)
        let measures = all.filter { $0.hasPrefix("layout.") || $0 == "sidebar.padding" }
        #expect(measures == ["layout.hideDelay", "layout.revealStripWidth"], "\(measures)")
        #expect(options("terminal.text").contains("window.padding"))
        #expect(SettingsSection.topic("window.spacing") == nil && SettingsSection.topic("tabs.metrics") == nil)
    }

    @Test func `where the tabs are is one topic; what was found by search is under its section and topic`() {
        #expect(
            options("tabs.placement") == [
                "tabs.mode", "tabs.bar.position", "sidebar.enabled", "sidebar.side", "sidebar.autoHide", "sidebar.width"
            ]
        )
        #expect(SettingsSection.topic("tabs.placement")?.section.title == "Tabs and sidebar")
        #expect(SettingsSection.heading(of: "terminal.cursor") == "Terminal \u{203A} Cursor")
        #expect(SettingsSection.topic("nowhere") == nil && SettingsSection.heading(of: "nowhere") == "nowhere")
    }

    @Test func `a section chosen in the sidebar shows its first topic; a topic shows itself`() {
        #expect(SettingsSection.shown(for: "section:web") == "web.address")
        #expect(SettingsSection.shown(for: "web.downloads") == "web.downloads")
        #expect(SettingsSection.shown(for: "section:none") == nil && SettingsSection.shown(for: nil) == nil)
    }
}
