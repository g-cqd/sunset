import AppKit
import SwiftUI

/// A colour of the settings file (`#rrggbb`, three sRGB bytes) and the colour a picker shows (roadmap 0086 E: the ANSI
/// palette's and the colour settings' bindings converted each way the same).
extension Color {
    init(sRGBBytes bytes: [UInt8]) {
        self.init(
            .sRGB,
            red: Double(bytes[0]) / 255,
            green: Double(bytes[1]) / 255,
            blue: Double(bytes[2]) / 255,
            opacity: 1
        )
    }

    /// Its three sRGB bytes, rounded and clamped; nil for a colour that has none.
    var sRGBBytes: [UInt8]? {
        guard let converted = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        return [converted.redComponent, converted.greenComponent, converted.blueComponent]
            .map { UInt8(max(0, min(255, ($0 * 255).rounded()))) }
    }
}
