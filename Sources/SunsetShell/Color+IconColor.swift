import AppKit
package import SunsetPane
package import SwiftUI

extension Color {
    /// An icon's colour, in sRGB.
    package init(_ color: IconColor) {
        self.init(.sRGB, red: Double(color.red) / 255, green: Double(color.green) / 255, blue: Double(color.blue) / 255)
    }
}
