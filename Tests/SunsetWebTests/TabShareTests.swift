import Foundation
import SunsetPane
import Testing

@testable import SunsetWeb
@testable import SunsetWebModel

/// ADR-0082: what a page is offered, and when a share stops.
@Suite("Sharing a tab") struct TabShareTests {
    private let work = UUID()
    private func source(_ title: String, profile: UUID?) -> ShareSource {
        ShareSource(id: UUID(), title: title, space: "Home", profile: profile, host: nil)
    }

    @Test func `a page is offered its own profile's tabs, every profile's only with the setting`() {
        let all = [source("Mine", profile: nil), source("Work's", profile: work)]
        #expect(TabShare.offered(all, to: nil, otherProfiles: false).map(\.title) == ["Mine"])
        #expect(TabShare.offered(all, to: work, otherProfiles: false).map(\.title) == ["Work's"])
        #expect(TabShare.offered(all, to: nil, otherProfiles: true).map(\.title) == ["Mine", "Work's"])
    }

    @Test func `it stops when either tab closes, the shared page goes to another site, or the person stops it`() {
        func stop(_ open: Bool = true, _ requester: Bool = true, _ now: String? = "a.example", _ person: Bool = false)
            -> TabShare.Stop?
        {
            TabShare.stop(
                sourceOpen: open,
                requesterOpen: requester,
                startHost: "a.example",
                hostNow: now,
                stoppedByPerson: person
            )
        }
        #expect(stop() == nil)
        #expect(stop(false) == .sourceClosed)
        #expect(stop(true, false) == .requesterClosed)
        #expect(stop(true, true, "b.example") == .sourceLeftSite)
        #expect(stop(true, true, "mail.a.example") == nil, "within its site it goes on")
        #expect(stop(true, true, "a.example", true) == .stopped)
        #expect(
            TabShare.stop(sourceOpen: true, requesterOpen: true, startHost: nil, hostNow: nil, stoppedByPerson: false)
                == nil
        )
    }
}

extension TabShareTests {
    /// ADR-0082: the shared tab stops being shared from its own panel; the call's track ends.
    @Test @MainActor func `a shared page stops every share of itself, and only those`() {
        let shared = WebContent(descriptor: PaneDescriptor(kind: "web", state: [:]), settings: WebSettings())
        let other = WebContent(descriptor: PaneDescriptor(kind: "web", state: [:]), settings: WebSettings())
        let call = WebContent(descriptor: PaneDescriptor(kind: "web", state: [:]), settings: WebSettings())
        func session(of page: WebContent) -> ShareSession {
            let feed = ShareFeed(frame: { nil }, isOpen: { true }, host: { nil }, page: { page })
            return ShareSession(source: UUID(), feed: feed, page: call, frameFunction: "f", endFunction: "e")
        }
        let one = session(of: shared)
        let two = session(of: other)
        one.start()
        two.start()
        #expect(WebShare.sessions.count >= 2)
        shared.stopBeingShared()
        #expect(one.stopped == .stopped && two.stopped == nil)
        #expect(!WebShare.sessions.contains { $0 === one })
        two.stop(.stopped)
    }
}
