import SunsetHelp
import SunsetPane
import SunsetShell
import SunsetShellBridge
import SwiftUI

/// "Open in ‹Space›" and, beside it, the menu of the other Spaces (the owner's "^ with selector"); with no Space to name (a
/// private window opened it), Open as Tab.
struct PopupOpenInButton: View {
    let current: SpaceModel?
    let spaces: [SpaceModel]
    let height: Double
    let move: (UUID?) -> Void
    @Environment(\.surfaceStyle) private var surface

    var body: some View {
        HStack(spacing: 0) {
            Button {
                move(current?.space.id)
            } label: {
                Text(current.map { "Open in \(Self.name(of: $0))" } ?? "Open as Tab")
                    .padding(.leading, PopupWindowLayout.capsuleEnd)
                    .padding(.trailing, Design.Space.s)
                    .frame(maxHeight: .infinity)
                    .contentShape(.rect)
            }
            Divider().padding(.vertical, Design.Space.s)
            Menu {
                ForEach(spaces, id: \.space.id) { space in
                    Button(Self.name(of: space)) { move(space.space.id) }
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(Design.Text.detail.weight(.semibold))
                    .padding(.leading, Design.Space.s)
                    .padding(.trailing, PopupWindowLayout.capsuleEnd)
                    .frame(maxHeight: .infinity)
                    .contentShape(.rect)
            }
            .menuStyle(.button)
            .menuIndicator(.hidden)
        }
        .buttonStyle(.plain)
        .font(Design.Text.secondary)
        .frame(height: height)
        // A capsule with the fields' fill and hairline, as the bars' groups are capsules.
        .background { Capsule().fill(Color.primary.opacity(Design.Fill.field)) }
        .overlay { Capsule().hairline(surface.layout) }
        .contentShape(Capsule())
        .fixedSize()
        .helpTopic(.popUps)
    }

    /// A Space's name as the Spaces menu says it: an unnamed one is Home.
    static func name(of space: SpaceModel) -> String {
        space.space.name.isEmpty ? "Home" : space.space.name
    }
}
