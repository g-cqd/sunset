import SwiftUI

/// The File menu's items about other browsers' things: installing an extension (roadmap 0109), into the window's profile;
/// importing another browser's bookmarks and extensions (roadmap 0111).
struct BrowserFileItems: View {
    var body: some View {
        Divider()
        Button("Install Extension\u{2026}") { AppActions.shared.installExtension() }
        Button("Import from Another Browser\u{2026}") { AppActions.shared.importFromBrowser() }
    }
}
