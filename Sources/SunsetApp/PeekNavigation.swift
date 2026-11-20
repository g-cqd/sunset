import SunsetShell
import SunsetWeb
import SwiftUI

/// A peek window's back and forward (the owner's note n66), one capsule as Open in ‹Space› is.
struct PeekNavigation: View {
    let page: WebContent
    let height: Double
    @Environment(\.surfaceStyle) private var surface

    var body: some View {
        HStack(spacing: 0) {
            arrow("chevron.left", enabled: page.canGoBack) { page.goBack() }
                .padding(.leading, PopupWindowLayout.capsuleEnd - Design.Space.xs)
            Divider().padding(.vertical, Design.Space.s)
            arrow("chevron.right", enabled: page.canGoForward) { page.goForward() }
                .padding(.trailing, PopupWindowLayout.capsuleEnd - Design.Space.xs)
        }
        .detachedCapsule(height: height, surface: surface)
    }

    private func arrow(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(Design.Text.detail.weight(.semibold))
                .padding(.horizontal, Design.Space.s)
                .frame(maxHeight: .infinity)
                .contentShape(.rect)
        }
        .disabled(!enabled)
        .accessibilityLabel(symbol == "chevron.left" ? "Back" : "Forward")
    }
}
