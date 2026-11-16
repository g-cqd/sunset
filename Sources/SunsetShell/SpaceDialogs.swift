import SunsetPane
package import SwiftUI

/// What a window asks before a Space that holds things is deleted (roadmap 0021 step S-c): its tabs and Favorites go to the
/// neighbouring Space, still running, or everything in it closes.
package struct SpaceDialogs: ViewModifier {
    let tabs: TabsModel

    package init(tabs: TabsModel) { self.tabs = tabs }

    private var target: SpaceModel? { tabs.deletingSpace.flatMap { tabs.spaces?.space($0) } }

    package func body(content: Content) -> some View {
        let target = target
        let neighbour = target.flatMap { tabs.spaces?.neighbour(of: $0) }
        content.confirmationDialog(
            "Delete the Space \u{201C}\(target?.space.name ?? "")\u{201D}?",
            isPresented: Binding(get: { tabs.deletingSpace != nil }, set: { if !$0 { tabs.deletingSpace = nil } }),
            titleVisibility: .visible
        ) {
            if let neighbour {
                Button("Move What It Holds to \(neighbour.space.name)") { tabs.answerDelete(moving: true) }
            }
            Button("Close Everything in It", role: .destructive) { tabs.answerDelete(moving: false) }
            Button("Cancel", role: .cancel) { tabs.deletingSpace = nil }
        } message: {
            Text(Self.sentence(tabs: target?.tabs.count ?? 0, kept: target?.favorites.favorites.count ?? 0))
        }
    }

    static func sentence(tabs: Int, kept: Int) -> String {
        let tabsPart = tabs == 1 ? "1 tab" : "\(tabs) tabs"
        let keptPart = kept == 1 ? "1 item in its Favorites" : "\(kept) items in its Favorites"
        return "It has \(tabsPart) and \(keptPart). What runs in a tab that closes is stopped."
    }
}
