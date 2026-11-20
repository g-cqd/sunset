import SunsetHelp
import SunsetPane
import SunsetShell
import SunsetShellBridge
import SwiftUI

/// "Open in ‹Space›" and, beside it, the menu of the other Spaces (the owner's "^ with selector"); with no Space to name (a
/// private window opened it), Open as Tab. One glass group, as the window bar's.
struct PopupOpenInButton: View {
    let current: SpaceModel?
    let spaces: [SpaceModel]
    let move: (UUID?) -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button {
                move(current?.space.id)
            } label: {
                Text(current.map { "Open in \(Self.name(of: $0))" } ?? "Open as Tab")
                    .font(Design.Text.secondary)
                    .padding(.leading, PopupWindowLayout.capsuleEnd)
                    .padding(.trailing, spaces.isEmpty ? PopupWindowLayout.capsuleEnd : Design.Space.s)
                    .frame(maxHeight: .infinity)
                    .contentShape(.rect)
            }
            // No Space to choose from (a private page: it goes to a private window): no menu.
            if !spaces.isEmpty {
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
        }
        .buttonStyle(.plain)
        .frame(height: PopupWindowLayout.capsuleHeight)
        .barGroup(margin: PopupWindowLayout.capsuleGap, top: true, control: PopupWindowLayout.capsuleHeight)
        .fixedSize()
        .helpTopic(.popUps)
    }

    /// A Space's name as the Spaces menu says it: an unnamed one is Home.
    static func name(of space: SpaceModel) -> String {
        space.space.name.isEmpty ? "Home" : space.space.name
    }
}
