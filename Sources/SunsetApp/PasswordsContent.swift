import Foundation
import Observation
import SunsetPane
import SunsetShell
import SwiftUI

/// The vault's page, a tab like Settings' (one in a window): the entry chosen in the Library's Passwords section, wide
/// enough for its fields (roadmap 0092 B). Which entry is not kept: it opens on none, and on nothing while locked.
@MainActor @Observable
final class PasswordsContent: PaneContent, PaneViewMaking {
    static let kind = PaneDescriptor.passwordsKind

    /// The entry shown.
    var selected: UUID?
    @ObservationIgnored var onExit: () -> Void = {}
    @ObservationIgnored var onFocusRequest: () -> Void = {}
    @ObservationIgnored var onChange: () -> Void = {}
    @ObservationIgnored weak var tabs: TabsModel?

    var title: String {
        "Passwords"
    }
    var detail: String? {
        nil
    }
    var glyph: PaneGlyph {
        .symbol("key")
    }
    var progress: Double? {
        nil
    }
    var closeWarning: String? {
        nil
    }
    var searchTerms: [String] {
        ["passwords", "vault", "logins"]
    }
    var descriptor: PaneDescriptor {
        .passwords
    }

    func setState(focused: Bool, visible: Bool) {}
    func stop() {}
    func makeView(_ context: PaneViewContext) -> AnyView {
        AnyView(PasswordsPage(content: self, context: context))
    }
}
