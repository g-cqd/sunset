import SwiftUI

/// The site's button at the start of the address field (web step g): the lock (or Not Secure), a dot while the page captures (a click stops it), and
/// a menu with this site's answers.
struct SiteButton: View {
    let content: WebContent
    @State private var open = false

    var body: some View {
        Button {
            open.toggle()
        } label: {
            HStack(spacing: 3) {
                if content.isNotSecure {
                    NotSecureMark()
                } else {
                    Image(systemName: "lock").font(.caption).foregroundStyle(.secondary)
                }
                if let dot = content.captureDot { Circle().fill(dot).frame(width: 6, height: 6) }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .help("This site's settings")
        .popover(isPresented: $open, arrowEdge: .bottom) { SiteSettingsPopover(content: content) }
    }
}
