package import SwiftUI

/// A field or a row of code (the owner's note n26): every text in it in the monospaced design, as `Text.code()`.
extension View {
    /// When `isCode`, else as it is.
    package func code(_ isCode: Bool = true) -> some View {
        fontDesign(isCode ? .monospaced : nil)
    }
}
