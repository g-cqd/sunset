import SunsetShell
import SwiftUI

/// What a fold in a settings row shows once open: its rows a little below the fold's label, so that a Form does not cut
/// the top of the first one (a field's border, seen 2026-11-18).
struct FoldContent<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.s) { content() }
            .padding(.top, Design.Space.s)
            .padding(.bottom, Design.Space.xs)
    }
}
