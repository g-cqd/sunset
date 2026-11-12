package import SwiftUI

extension View {
    /// The one field of Sunset (design 0003, step 3): the address field, the history's search, a row's name edited in place, the find bar's
    /// text. A leaf corner, `Design.Size.field` tall, `Design.Space.m` from its edges, a faint fill and the hairline so that its edge shows on
    /// every background (a private field is dark and its edge would vanish on a dark window without the line).
    package func fieldSurface(dark: Bool = false, height: Double? = Design.Size.field) -> some View {
        modifier(FieldSurface(dark: dark, height: height))
    }
}
