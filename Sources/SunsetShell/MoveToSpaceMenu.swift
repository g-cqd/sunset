import SunsetPane
import SwiftUI

/// Move to Space, in the menu of a tab or of a selection (roadmap 0021 step S-c): the other Spaces, by name. The tabs go
/// there running and the window follows them. Not shown while there is one Space.
struct MoveToSpaceMenu: View {
    let tabs: TabsModel
    let rows: [RowTarget]

    var body: some View {
        if let spaces = tabs.spaces, spaces.spaces.count > 1 {
            Menu("Move to Space") {
                ForEach(spaces.spaces.filter { $0 !== tabs.space }, id: \.space.id) { space in
                    Button(space.space.name) { tabs.move(rows: rows, to: space) }
                }
            }
        }
    }
}
