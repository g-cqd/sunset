import SwiftUI

extension View {
    /// A name edited in place in a row: the shared field, as tall as the close button so that the row keeps its height, its text where the
    /// row's title was (the field's edge reaches out towards the row's).
    func inPlaceField() -> some View { modifier(InPlaceField()) }
}
