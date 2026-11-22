import SunsetShell
import SwiftUI

/// The site's button at the start of the address field: the lock (or Not Secure), a dot while the page captures (a click stops it), and
/// a menu with this site's answers.
struct SiteButton: View {
    let content: WebContent

    var body: some View {
        // One of the rows' buttons, its fill under the pointer.
        RowGlyphButton(help: "This site's settings") {
            content.showsSiteSettings.toggle()
        } glyph: {
            HStack(spacing: Design.Space.xs) {
                if content.isNotSecure {
                    NotSecureMark()
                } else {
                    Image(systemName: "lock")
                }
                if let mark = content.captureMark { Circle().fill(mark.color).frame(width: 6, height: 6) }
            }
            .padding(.horizontal, Design.Space.xs)
        }
        .popover(isPresented: Bindable(content).showsSiteSettings, arrowEdge: .bottom) {
            SiteSettingsPopover(content: content).solidPopoverBackground()
        }
    }
}
