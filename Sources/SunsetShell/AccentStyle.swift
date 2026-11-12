package import SwiftUI

/// The accent a window draws with (`Design.Accent.style(dark:)`): its colour, and the ink for text and symbols on it.
package struct AccentStyle: Equatable {
    package var color: Color
    package var ink: Color

    package init(color: Color = Color(nsColor: .controlAccentColor), ink: Color = .white) {
        self.color = color
        self.ink = ink
    }
}

extension EnvironmentValues {
    @Entry package var accent = AccentStyle()
}
