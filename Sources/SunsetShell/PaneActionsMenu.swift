import SunsetPane
import SwiftUI

/// What the contents of a tab's panes add to its menu (`PaneContent.menuActions`): one pane's items in the menu itself, a
/// split's under each pane's name (the owner's note n8: the split's container offers what fits its parts). The tab is shown
/// and the pane given the keyboard first, so that what opens beside the page (its site's settings) has it.
struct PaneActionsMenu: View {
    let tabs: TabsModel
    let panes: [PaneID]
    let show: () -> Void

    var body: some View {
        let offering = panes.compactMap { pane in tabs.content(pane).map { (pane, $0) } }
            .filter { !$1.menuActions.isEmpty }
        if !offering.isEmpty {
            Divider()
            if offering.count == 1, panes.count == 1, let (pane, content) = offering.first {
                items(content.menuActions, of: pane)
            } else {
                ForEach(offering, id: \.0) { pane, content in
                    Menu(content.title) { items(content.menuActions, of: pane) }
                }
            }
        }
    }

    private func items(_ actions: [PaneMenuAction], of pane: PaneID) -> some View {
        ForEach(actions.indices, id: \.self) { index in
            let action = actions[index]
            if action.children.isEmpty {
                button(action, of: pane)
            } else {
                Menu(action.title) {
                    ForEach(action.children.indices, id: \.self) { child in button(action.children[child], of: pane) }
                }
            }
        }
    }

    private func button(_ action: PaneMenuAction, of pane: PaneID) -> some View {
        Button(action.title) {
            show()
            tabs.focus(pane)
            action.run()
        }
    }
}
