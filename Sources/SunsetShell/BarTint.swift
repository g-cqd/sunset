package import SwiftUI

/// The fill inside the bars' glass and the scheme of their controls (`appearance.barTint`).
package enum BarTint: String, Sendable, Equatable {
    case scheme, dark, light

    /// The scheme the bar's controls use, under a window of `outer` scheme.
    package func resolved(in outer: ColorScheme) -> ColorScheme {
        switch self {
            case .scheme: outer
            case .dark: .dark
            case .light: .light
        }
    }

    /// The fill inside the glass: black for dark controls, white for light ones.
    package static func fill(for scheme: ColorScheme) -> Color { scheme == .dark ? .black : .white }
}
