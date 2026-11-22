import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// Under the address field: the pages' questions, and what macOS must allow Sunset itself. macOS is asked about only when a site may use what it would refuse: no call to action
/// for something nothing needs.
@MainActor
@Suite("What macOS must allow Sunset")
struct SystemAskTests {
    @Test func `nothing is asked while no site may use what macOS has not allowed`() {
        let store = SitePermissions()
        let statuses: [SystemAsk.Need: SystemAsk.Status] = [.notifications: .notAsked, .camera: .denied]
        #expect(SystemAsk.needed(statuses, sites: store).isEmpty)
    }

    @Test func `a site allowed to notify while macOS was not asked: allow; refused: open System Settings`() {
        let store = SitePermissions()
        store.set(.allow, .notifications, for: "chat.example")
        #expect(
            SystemAsk.needed([.notifications: .notAsked], sites: store) == [
                SystemAsk(need: .notifications, status: .notAsked)
            ]
        )
        #expect(SystemAsk.needed([.notifications: .denied], sites: store).first?.action == .openSettings)
        #expect(SystemAsk.needed([.notifications: .notAsked], sites: store).first?.action == .ask)
        #expect(SystemAsk.needed([.notifications: .allowed], sites: store).isEmpty)
    }

    @Test
    func `the camera, the microphone and the location are needed by a site allowed, or by the default allowing them`() {
        let store = SitePermissions()
        store.set(.allow, .camera, for: "meet.example")
        store.defaults[.location] = .allow
        let needed = SystemAsk.needed([.camera: .denied, .microphone: .denied, .location: .denied], sites: store)
        #expect(needed.map(\.need) == [.camera, .location])
        #expect(needed.allSatisfy { $0.action == .openSettings })
        #expect(needed.first?.sentence.contains("camera") == true)
    }
}
