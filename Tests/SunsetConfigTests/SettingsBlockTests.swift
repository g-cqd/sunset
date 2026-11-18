import Testing

@testable import SunsetConfig

/// The owner's note n13 (2026-11-18): "more structure and nest some configurations, also some input of the settings pages
/// don't even have any labels … add separators … (some entry points … the adding a new search engine, or the settings per
/// website)". A page is made of blocks: groups under a heading, and each list on its own, its note under it.
@Suite("A settings page in blocks") struct SettingsBlockTests {
    /// The most options a page shows together without a heading.
    static let mostUngrouped = 6

    static var topics: [SettingsTopic] { SettingsSection.all.flatMap(\.topics) }

    @Test func `a list is a block of its own, headed by its title`() {
        for topic in Self.topics {
            for block in SettingsBlock.blocks(topic.first + topic.further) {
                let lists = block.options.filter(\.isList)
                if lists.isEmpty { continue }
                #expect(
                    block.isList && lists.count == 1 && block.options[0].isList,
                    "\(topic.id): a list shares its block"
                )
                #expect(block.options.dropFirst().allSatisfy { $0.group == block.title }, "\(topic.id)")
                #expect(block.title == lists[0].title, "\(topic.id)")
            }
        }
    }

    @Test func `the blocks keep every option once, in order`() {
        for topic in Self.topics {
            let options = topic.first
            #expect(SettingsBlock.blocks(options).flatMap(\.options).map(\.id) == options.map(\.id), "\(topic.id)")
        }
    }

    @Test func `no page is a long run of options without a heading`() {
        var packed: [String] = []
        for topic in Self.topics {
            for block in SettingsBlock.blocks(topic.first)
            where block.title == nil
                && block.options.count > Self.mostUngrouped
            {
                packed.append("\(topic.id): \(block.options.count)")
            }
        }
        #expect(packed.isEmpty, "\(packed)")
    }

    @Test func `no heading says again the topic's title`() {
        for topic in Self.topics {
            for block in SettingsBlock.blocks(topic.first + topic.further) {
                #expect(block.title != topic.title, "\(topic.id): “\(topic.title)” twice")
            }
        }
    }

    @Test func `the search engines, the websites and each site are lists`() {
        for id in [
            "web.engines", "web.permissions", "web.agent", "web.sites", "profiles.list", "web.blockingLists", "features"
        ] {
            #expect(SettingsOption.named(id)?.isList == true, "\(id)")
        }
    }
}

extension SettingsBlockTests {
    /// The owner's notes n38, n39 (2026-11-18): "profiles should be more separated from each other … a subsection belongs to the
    /// profile set above it", and New Profile "at a location that does not make it confusable with another button for a
    /// specific profile". The profiles draw a section each; no other list does.
    @Test func `the profiles draw their own sections, one a profile`() {
        let owning = SettingsOption.all.filter(\.ownsSections).map(\.id)
        #expect(owning == ["profiles.list"])
    }
}
