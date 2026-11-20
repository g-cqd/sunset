package import SwiftUI

extension View {
    /// A popover's own background, the window's colour, opaque: the system's glass took on what was behind it (seen
    /// 2026-11-20, task t24: the icon picker over a terminal, dark glyphs on dark, the hidden page's colours showing through).
    package func solidPopoverBackground() -> some View {
        presentationBackground(Color(nsColor: .windowBackgroundColor))
    }
}
