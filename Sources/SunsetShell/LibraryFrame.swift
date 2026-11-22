package import SwiftUI

/// The sidebar and the Library's rail side by side: the list keeps the width the tabs have, and the rail is added at the
/// window's edge past a gutter, so that opening the Library widens the sidebar in place. The list is one view whether or
/// not the rail shows: what is in it changes, it is not taken away and brought back.
package struct LibraryFrame<List: View, Rail: View>: View {
    /// The rail is at the leading end (a sidebar on the left: the window's edge is there).
    let railLeading: Bool
    let buttons: SidebarButtons
    let railShown: Bool
    @ViewBuilder let list: () -> List
    @ViewBuilder let rail: () -> Rail

    package init(
        railLeading: Bool,
        buttons: SidebarButtons,
        railShown: Bool,
        @ViewBuilder list: @escaping () -> List,
        @ViewBuilder rail: @escaping () -> Rail
    ) {
        self.railLeading = railLeading
        self.buttons = buttons
        self.railShown = railShown
        self.list = list
        self.rail = rail
    }

    package var body: some View {
        HStack(spacing: 0) {
            if railLeading { railColumn }
            // One geometry for the list and whatever comes and goes in it: a section shown over the tabs moves with them as
            // the sidebar widens, instead of appearing where it will end up while the tabs are still on their way.
            list().frame(maxWidth: .infinity, maxHeight: .infinity).geometryGroup()
            if !railLeading { railColumn }
        }
    }

    /// The rail, as wide as a button, its gap to the window's edge on one side and the gutter to the list on the other. It
    /// fades in where it is: the sidebar's width is what moves.
    @ViewBuilder private var railColumn: some View {
        if railShown {
            rail()
                .frame(width: buttons.metrics.size.width)
                .padding(railLeading ? .leading : .trailing, buttons.gap)
                .padding(railLeading ? .trailing : .leading, SectionRail.gutter)
                .transition(.opacity)
        }
    }
}
