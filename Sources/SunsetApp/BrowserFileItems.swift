import SwiftUI

/// The File menu's items about other browsers' things: installing an extension, into the window's profile; importing
/// another browser's bookmarks and extensions; in Sunset WebKit, bringing Sunset's cookies (roadmap 0112 E).
struct BrowserFileItems: View {
    var body: some View {
        Divider()
        Button("Install Extension\u{2026}") { AppActions.shared.installExtension() }
        Button("Import from Another Browser\u{2026}") { AppActions.shared.importFromBrowser() }
        // Sunset WebKit only: Sunset's sign-ins, one way.
        if AppCookieTransfer.isOffered {
            Button("Bring Cookies from Sunset") { AppCookieTransfer.bring() }
        }
    }
}
