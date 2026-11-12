import SwiftUI

/// The name of a row edited in place: it takes the keyboard at once; Return or leaving keeps what was typed, Escape changes nothing.
struct RenameField: View {
    let done: (String?) -> Void
    @State private var text: String

    init(start: String, done: @escaping (String?) -> Void) {
        self.done = done
        _text = State(initialValue: start)
    }

    var body: some View {
        InPlaceNameField(text: $text, commit: { done(text) }, cancel: { done(nil) }).inPlaceField()
    }
}
