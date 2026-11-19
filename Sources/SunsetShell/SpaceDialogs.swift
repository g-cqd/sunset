import SunsetPane
package import SwiftUI

/// A window's dialogs about Spaces (roadmap 0021 step S-c): the editor of a Space, as a sheet; and what is asked before a
/// Space that has tabs is deleted: they go to the neighbouring Space, still running, or close.
package struct SpaceDialogs: ViewModifier {
    let tabs: TabsModel

    package init(tabs: TabsModel) {
        self.tabs = tabs
    }

    private var target: SpaceModel? {
        tabs.deletingSpace.flatMap { tabs.spaces?.space($0) }
    }

    package func body(content: Content) -> some View {
        let target = target
        let neighbour = target.flatMap { tabs.spaces?.neighbour(of: $0) }
        content
            .sheet(item: Binding(get: { tabs.spaceDraft }, set: { tabs.spaceDraft = $0 })) { draft in
                SpaceSheet(tabs: tabs, draft: draft)
            }
            .confirmationDialog(
                "Delete the Space \u{201C}\(target?.space.name ?? "")\u{201D}?",
                isPresented: Binding(get: { tabs.deletingSpace != nil }, set: { if !$0 { tabs.deletingSpace = nil } }),
                titleVisibility: .visible
            ) {
                if let neighbour {
                    Button("Move Its Tabs to \(neighbour.space.name)") { tabs.answerDelete(moving: true) }
                }
                Button("Close Its Tabs", role: .destructive) { tabs.answerDelete(moving: false) }
                Button("Cancel", role: .cancel) { tabs.deletingSpace = nil }
            } message: {
                Text(Self.sentence(tabs: target?.tabs.count ?? 0))
            }
    }

    static func sentence(tabs: Int) -> String {
        (tabs == 1 ? "It has 1 tab." : "It has \(tabs) tabs.") + " What runs in a tab that closes is stopped."
    }
}
