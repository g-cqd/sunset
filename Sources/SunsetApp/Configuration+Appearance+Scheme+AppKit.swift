import AppKit
import SunsetConfig
import SwiftUI

extension Configuration.Appearance.Scheme {
    /// The AppKit appearance that locks a window to this scheme; nil: follow the system.
    var nsAppearance: NSAppearance? {
        switch self {
            case .dark: NSAppearance(named: .darkAqua)
            case .light: NSAppearance(named: .aqua)
            case .system: nil
        }
    }

    /// The SwiftUI scheme to prefer; nil: follow the system.
    var colorScheme: ColorScheme? {
        switch self {
            case .dark: .dark
            case .light: .light
            case .system: nil
        }
    }
}
