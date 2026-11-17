import SwiftUI

/// The name of a row edited in place: it takes the keyboard at once; Return or leaving keeps what was typed, Escape changes nothing.
struct RenameField: View {
    @Binding var text: String
    let done: (String?) -> Void

    var body: some View {
        InPlaceNameField(text: $text, commit: { done(text) }, cancel: { done(nil) }).inPlaceField()
    }
}
