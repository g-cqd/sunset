import SwiftUI

/// The mark of a document with edits that are not saved: a small dot, as the system's close button has in a window's title bar.
struct EditedMark: View {
    var body: some View {
        Circle().fill(.secondary)
            .frame(width: Design.Size.editedMark, height: Design.Size.editedMark)
            .help("Edited, not saved")
            .accessibilityLabel("Edited, not saved")
    }
}
