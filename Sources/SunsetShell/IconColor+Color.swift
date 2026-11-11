import AppKit
package import SunsetPane
package import SwiftUI

extension IconColor {
    /// A colour chosen in the system's colour panel, brought to sRGB; nil when it cannot be.
    package init?(_ color: Color) {
        guard let rgb = NSColor(color).usingColorSpace(.sRGB) else { return nil }
        func byte(_ value: CGFloat) -> UInt8 { UInt8((min(max(value, 0), 1) * 255).rounded()) }
        self.init(red: byte(rgb.redComponent), green: byte(rgb.greenComponent), blue: byte(rgb.blueComponent))
    }
}
