import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// Roadmap 0050: a profile's pages share the answers kept, with defaults of their own.
@MainActor @Suite("A profile's own defaults") struct SitePermissionsSharingTests {
    @Test func `answers are shared both ways; what is not answered falls to the profile's defaults`() {
        let shared = SitePermissions()
        shared.defaults = [.camera: .deny]
        let profile = SitePermissions.sharing(shared, defaults: [.camera: .allow])
        #expect(profile.answer(.camera, for: "meet.example") == .allow, "the profile's default")
        #expect(shared.answer(.camera, for: "meet.example") == .deny)
        shared.set(.deny, .camera, for: "meet.example")
        #expect(profile.answer(.camera, for: "meet.example") == .deny, "an answer kept is shared")
        profile.set(.allow, .microphone, for: "meet.example")
        #expect(shared.answer(.microphone, for: "meet.example") == .allow, "given from the profile, kept for all")
    }
}
