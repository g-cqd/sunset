import Testing

@testable import SunsetConfig

/// A profile sets otherwise only what differs, only what a profile may.
@Suite("A profile's own settings") struct ProfileOverridesTests {
    @Test func `a profile may set search, privacy, network and downloads, nothing else`() {
        let keys = Set(ProfileOverrides.profileKeys)
        for key in [
            "web.engine", "web.suggestions", "web.blocking", "web.agent", "web.permissions.camera", "web.keep.siteData",
            "web.proxy", "web.downloadFolder", "web.askWhereToSave"
        ] {
            #expect(keys.contains(key), "\(key)")
        }
        #expect(!keys.contains("appearance.theme") && !keys.contains("terminal.font.name"))
        #expect(keys.isSubset(of: ConfigurationKeys.all))
    }

    @Test func `only what differs is kept, as the file writes it`() {
        let app = Configuration()
        var profile = app
        profile.web.engine = "DuckDuckGo"
        profile.web.proxy = "socks5://127.0.0.1:1080"
        profile.appearance.haptics.toggle()
        let overrides = ProfileOverrides.diff(profile: profile, app: app)
        #expect(overrides == ["web.engine": #""DuckDuckGo""#, "web.proxy": #""socks5://127.0.0.1:1080""#])
        #expect(ProfileOverrides.diff(profile: app, app: app).isEmpty)
    }

    @Test func `applied onto all profiles' settings, which it follows elsewhere`() {
        var app = Configuration()
        app.web.blocking = false
        let profile = ProfileOverrides.apply(["web.engine": #""DuckDuckGo""#, "theme": #""nord""#], to: app)
        #expect(profile.web.engine == "DuckDuckGo")
        #expect(profile.web.blocking == false, "what it did not set follows all profiles")
        #expect(profile.theme == app.theme, "a key a profile may not set is left")
        #expect(ProfileOverrides.apply([:], to: app) == app)
    }
}

extension ProfileOverridesTests {
    /// With a profile chosen, Settings lists only what a profile can set.
    @Test func `with a profile chosen, the options and topics a profile can set`() {
        let options = SettingsOption.all.filter(\.isProfileSetting).map(\.id)
        #expect(
            options.contains("web.engine") && options.contains("web.proxy") && options.contains("web.downloadFolder")
        )
        #expect(options.contains("web.permissions"), "the defaults of what sites may do")
        #expect(!options.contains("appearance.theme") && !options.contains("web.engines"))
        let topics = SettingsSection.all.flatMap(\.topics).filter(\.hasProfileSettings).map(\.id)
        #expect(topics.contains("web.search") && topics.contains("web.proxy") && topics.contains("web.downloads"))
        #expect(!topics.contains("appearance.theme") && !topics.contains("terminal.text"))
    }
}

extension ProfileOverridesTests {
    @Test func `with a profile chosen, a section opens on its first topic a profile can set`() {
        #expect(SettingsSection.shown(for: SettingsSection.sectionPrefix + "web", profileOnly: true) == "web.search")
        #expect(
            SettingsSection.shown(for: SettingsSection.sectionPrefix + "privacy", profileOnly: true)
                == "privacy.browsing"
        )
    }
}
