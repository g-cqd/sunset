package import SwiftUI

/// A sidebar button's symbol at the pin's size.
package struct SidebarSymbol: View {
    let name: String
    let filled: Bool

    package init(name: String, filled: Bool = false) {
        self.name = name
        self.filled = filled
    }

    package var body: some View {
        Image(systemName: name).symbolVariant(filled ? .fill : .none)
            .font(.system(size: Design.Symbol.row, weight: .regular))
    }
}
