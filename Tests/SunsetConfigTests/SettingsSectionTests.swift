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
                "web.historyKeep", "web.clearHistoryOnQuit", "web.clearWebsiteDataOnQuit", "web.privateWindowShares"
            ]
        )
    }

    @Test func `a number of the layout is with the thing it measures; the tab metrics are two topics (the owner)`() {
        #expect(
            options("window.titleBar").suffix(3) == [
                "layout.lightsInset", "layout.lightsGap", "layout.floatingLightsExtra"
            ]
        )
        #expect(options("window.spacing").prefix(2) == ["window.padding", "sidebar.padding"])
        let floating = options("tabs.floating")
        #expect(floating.filter { $0.hasPrefix("layout.floating") }.count == 8 && floating.contains("layout.hideDelay"))
        let docked = options("tabs.metrics")
        #expect(docked.count == 9 && docked.last == "layout.sidebarButtonRadius")
        #expect(docked.allSatisfy { $0.hasPrefix("layout.") && !$0.hasPrefix("layout.floating") })
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
