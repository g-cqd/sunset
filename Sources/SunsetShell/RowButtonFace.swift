import SwiftUI

/// The face of a small button at a row's end (roadmap 0086 E: the close button and the clear button were drawn whole in the
/// sidebar's row, the top bar's tab and a folder's row): a symbol at the controls' size and weight in a square the close
/// button's size, filled as `RowFill.closeButton` says.
struct RowButtonFace: View {
    let symbol: String
    let side: Double
    let radius: Double
    var armed = false
    var over = false
    /// The symbol in the secondary colour (a clear button), not the primary.
    var quiet = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: Design.Symbol.badge, weight: Design.Symbol.weight))
            .foregroundStyle(
                armed ? AnyShapeStyle(Color.white) : quiet ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary)
            )
            .frame(width: side, height: side)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill((armed ? Color.red : Color.primary).opacity(RowFill.closeButton(armed: armed, over: over)))
            )
            .contentShape(.rect)
    }
}
