import SunsetShell
package import SwiftUI

/// The list under an address field while it is typed in (web step c): as wide as the content it lies over, the rows of the command bar.
package struct AddressSuggestionList: View {
    let typing: AddressTyping
    let places: Set<AddressTyping.Place>
    var page: WebContent?
    @Environment(\.surfaceStyle) private var surface

    /// The list for a field typed in at one of `places`; for `.pane`, only the field of `page`.
    package init(typing: AddressTyping, places: Set<AddressTyping.Place>, page: WebContent? = nil) {
        self.typing = typing
        self.places = places
        self.page = page
    }

    package var body: some View {
        let rows = typing.rows
        if typing.isActive, places.contains(typing.place), page == nil || typing.page === page, !rows.isEmpty {
            ChoiceList(rows: rows, selection: min(typing.selection, rows.count - 1), radius: surface.leafRadius) {
                typing.take($0)
            }
            .surface(surface.shape, shadow: .popover)
            .padding(Design.Space.m)
        }
    }
}
