import SunsetShell
import SwiftUI

/// The question of a page (web step g): a small glass panel at the top of its pane, under its address: the site and what it wants, Allow Once,
/// Allow, Don't Allow. The page keeps working meanwhile. Without Sunset.app's identity it says why it cannot allow, and only closes.
struct PermissionPanel: View {
    let request: PermissionRequest
    /// Where Allow and Don't Allow are kept (a private page's own answers).
    let store: SitePermissions
    @Environment(\.surfaceStyle) private var surface

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.l) {
            HStack(spacing: Design.Space.m) {
                ForEach(request.permissions, id: \.self) { permission in
                    Image(systemName: permission.symbol).foregroundStyle(.secondary)
                }
                Text(request.sentence).fixedSize(horizontal: false, vertical: true)
            }
            if request.unavailable {
                Text(
                    "Sunset can pass this on only when it runs as Sunset.app (Scripts/make-app.sh), which macOS asks in turn."
                )
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
                HStack {
                    Spacer()
                    Button("OK") { request.choose(.deny, keepIn: store) }.keyboardShortcut(.defaultAction)
                }
            } else {
                HStack {
                    Spacer()
                    Button("Don't Allow") { request.choose(.deny, keepIn: store) }
                    Button("Allow Once") { request.choose(.allowOnce, keepIn: store) }
                    Button("Allow") { request.choose(.allow, keepIn: store) }.keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(Design.Space.xl)
        .frame(width: Design.Width.panel, alignment: .leading)
        .surface(surface.panelShape, shadow: .popover)
        .padding(Design.Space.l)
    }
}
