import SunsetPane
import SwiftUI

/// The first row of a tab's menu (n78, t287; the owner, 2026-11-17): for several tabs selected, or a split tab, the layouts
/// of as many panes as they hold, as a row of pictures in the menu's own ink (white on a dark menu, black on a light one).
struct TabLayoutMenu: View {
    let tabs: TabsModel
    let row: RowTarget

    var body: some View {
        let ids = tabs.layoutTabs(for: row)
        let presets = tabs.workspace.presets(for: ids)
        if !presets.isEmpty {
            ControlGroup {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        tabs.apply(preset, to: ids)
                    } label: {
                        Label {
                            Text(preset.title)
                        } icon: {
                            Image(nsImage: PresetShape.image(preset))
                        }
                    }
                }
            } label: {
                Text("Layout")
            }
            .controlGroupStyle(.palette)
            .tint(.primary)
            Divider()
        }
    }
}
