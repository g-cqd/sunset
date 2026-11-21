import SunsetPane
import SwiftUI

/// The first row of a tab's menu (n78, t287; the owner, 2026-11-17): for several tabs selected, or a split tab, the layouts
/// of as many panes as they hold, as a row of pictures in the menu's own ink (white on a dark menu, black on a light one).
struct TabLayoutMenu: View {
    let tabs: TabsModel
    let row: RowTarget
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        // Several rows selected, favorites among them (they leave the Favorites for it); or one split tab.
        let rows = tabs.layoutRows(tabs.rows(actingOn: row))
        let split = tabs.layoutTabs(for: row)
        let presets = rows.count > 1 ? tabs.layoutPresets(for: rows) : tabs.workspace.presets(for: split)
        if !presets.isEmpty {
            ControlGroup {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        if rows.count > 1 { tabs.apply(preset, to: rows) } else { tabs.apply(preset, to: split) }
                    } label: {
                        Label {
                            Text(preset.title)
                        } icon: {
                            Image(nsImage: PresetShape.image(preset, dark: scheme == .dark))
                        }
                    }
                }
            } label: {
                Text("Layout")
            }
            .controlGroupStyle(.palette)
            Divider()
        }
    }
}
