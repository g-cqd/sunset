import SunsetPane
import SwiftUI

extension View {
    /// The row of a kept entry under the pointer is the hover card's while the entry is open ("no preview on loaded
    /// favorites tabs or pinned tabs"), as a tab's row is.
    func hoverPreview(_ tabs: TabsModel, entry: Favorites.NodeID) -> some View {
        modifier(HoverPreview(tabs: tabs, target: .entry(entry)))
    }

    /// The row of a folder under the pointer is the hover card's: a list of the tabs it holds.
    func hoverPreview(_ tabs: TabsModel, folder: Favorites.NodeID) -> some View {
        modifier(HoverPreview(tabs: tabs, target: .folder(folder)))
    }
}
