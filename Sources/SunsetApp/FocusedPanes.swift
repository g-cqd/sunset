import SunsetMarkdown
import SunsetShell
import SunsetTerminal
import SunsetWeb
import SwiftUI

/// What the menus act on in a window: its shown pane, as the kind it is (the others are nil, and their items are off).
struct FocusedPanes: ViewModifier {
    let tabs: TabsModel

    func body(content: Content) -> some View {
        content
            .focusedSceneValue(\.terminalModel, tabs.selectedTerminal)
            .focusedSceneValue(\.webPage, tabs.selectedContent as? WebContent)
            .focusedSceneValue(\.documentPane, tabs.selectedContent as? DocumentContent)
    }
}
