import Foundation
import Testing

@testable import SunsetWeb

/// Roadmap 0050 E (the owner's answer, 2026-11-18: "that profile only"): a profile's own site rules; with none for a site, all
/// profiles' apply. No profile (the first) is all profiles'.
@MainActor @Suite("A profile's own site rules") struct SiteRulesProfileTests {
    private let work = UUID()
    private let page = URL(string: "https://mail.example.org/inbox") ?? URL(filePath: "/")

    @Test func `a profile's rule wins for it alone; without one, all profiles' rule applies`() {
        let rules = SiteRules<String>(encode: { $0 }, decode: { $0 })
        rules.set("all", for: "example.org")
        rules.set("work", for: "example.org", profile: work)
        #expect(rules.value(for: page) == "all")
        #expect(rules.value(for: page, profile: work) == "work")
        #expect(rules.value(for: page, profile: UUID()) == "all", "another profile has none")
        #expect(rules.value(for: "mail.example.org", profile: work) == "work")
        #expect(rules.rule(for: "example.org", profile: work) == "work" && rules.rule(for: "example.org") == "all")
        #expect(rules.rules(profile: work).map(\.host) == ["example.org"])
        rules.set(nil, for: "example.org", profile: work)
        #expect(rules.value(for: page, profile: work) == "all")
    }

    @Test func `kept apart in the sealed table, read back`() throws {
        let path = FileManager.default.temporaryDirectory.appending(path: "rules-\(UUID().uuidString).sqlite").path
        defer { try? FileManager.default.removeItem(atPath: path) }
        let one = SiteRules<String>(table: try TestState.table("r", at: path), encode: { $0 }, decode: { $0 })
        one.set("all", for: "example.org")
        one.set("work", for: SitePattern.subdomains("example.org"), profile: work)
        let two = SiteRules<String>(table: try TestState.table("r", at: path), encode: { $0 }, decode: { $0 })
        #expect(two.value(for: page) == "all" && two.value(for: page, profile: work) == "work")
        #expect(two.rules.map(\.host) == ["example.org"], "all profiles' list holds no profile's")
    }
}

extension SiteRulesProfileTests {
    /// The stores that are not `SiteRules` keep a profile's own the same way (written after the change, not red first).
    @Test func `zoom, pauses, answers and Each site: a profile's own, all profiles' otherwise`() {
        let zoom = SiteZoom()
        zoom.set(1.5, for: "example.org", remember: false, profile: work)
        #expect(zoom.level(for: "example.org", profile: work) == 1.5 && zoom.level(for: "example.org") == 1)
        #expect(zoom.sites.isEmpty && zoom.sites(profile: work).map(\.host) == ["example.org"])
        let pauses = BlockingPauses()
        pauses.set(true, for: "example.org", profile: work)
        #expect(pauses.isPaused("mail.example.org", profile: work) && !pauses.isPaused("mail.example.org"))
        #expect(pauses.paused.isEmpty && pauses.paused(profile: work) == ["example.org"])
        let shared = SitePermissions()
        let mine = SitePermissions.sharing(shared, defaults: [:], profile: work)
        mine.set(.allow, .camera, for: "meet.example")
        #expect(mine.answer(.camera, for: "meet.example") == .allow)
        #expect(shared.answer(.camera, for: "meet.example") == SitePermission.camera.defaultAnswer)
        #expect(shared.answeredSites.isEmpty && shared.answeredSites(profile: work).map(\.host) == ["meet.example"])
        let stores = SiteSummary.Stores(
            permissions: shared,
            agents: SiteAgents(),
            pauses: pauses,
            zoom: zoom,
            spaces: SiteSpaces.make(),
            hidden: HiddenElements.make(),
            kept: KeptSites()
        )
        #expect(SiteSummary.rows(stores) { _ in nil }.isEmpty)
        let row = SiteSummary.rows(stores, profile: work) { _ in nil }
        #expect(row.map(\.host) == ["example.org", "meet.example"])
        SiteSummary.forget("example.org", in: stores, profile: work)
        #expect(zoom.level(for: "example.org", profile: work) == 1 && !pauses.isPaused("example.org", profile: work))
    }
}
