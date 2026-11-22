import SunsetPane
import SunsetShellModel
package import SwiftUI

/// A window's dialogs about Spaces: the editor of a Space, as a sheet; and what is asked before a Space that has tabs
/// is deleted: they go to the neighbouring Space, still running, or close.
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
            .sunsetAlert(
                isPresented: Binding(get: { tabs.deletingSpace != nil }, set: { if !$0 { tabs.deletingSpace = nil } }),
                // Cancel (0) is the default: Return deletes nothing.
                SunsetAlert(
                    title: "Delete the Space \u{201C}\(target?.space.shownName ?? "")\u{201D}?",
                    message: Self.sentence(tabs: target?.tabs.count ?? 0),
                    buttons: [.cancel("Cancel"), .destructive("Close Its Tabs")]
                        + (neighbour.map { [.plain("Move Its Tabs to \($0.space.shownName)")] } ?? []),
                    defaultButton: 0
                )
            ) { pressed in
                switch pressed {
                    case 1: tabs.answerDelete(moving: false)
                    case 2: tabs.answerDelete(moving: true)
                    default: tabs.deletingSpace = nil
                }
            }
    }

    static func sentence(tabs: Int) -> String {
        (tabs == 1 ? "It has 1 tab." : "It has \(tabs) tabs.") + " What runs in a tab that closes is stopped."
    }
}
