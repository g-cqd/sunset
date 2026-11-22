import SunsetMetrics
import SwiftUI

/// The look of `View.inPlaceField()`: the row itself is the field (a field inside the row "looks weird and too tight").
/// The text is where the title was, in its font, with no surface of its own; the row says it is being edited by its
/// outline (`InsettableShape.focusHairline`).
struct InPlaceField: ViewModifier {
    func body(content: Content) -> some View {
        // As tall as its line, as the title it replaces: the row keeps its height.
        content.fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
    }
}
