package import SwiftUI

extension RowFill.SiteTint {
    /// The fill as a colour.
    package var color: Color {
        Color(red: Double(rgb[0]) / 255, green: Double(rgb[1]) / 255, blue: Double(rgb[2]) / 255).opacity(opacity)
    }
}
