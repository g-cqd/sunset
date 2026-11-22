import SunsetPane
import SwiftUI

/// A Space's editor ("more contained, with 3 fields, and a save and cancel"): its name, its colour, which tints the
/// window that shows the Space and nothing else, and its icon. The colour and the icon are fields that open their
/// pickers; neither picker is shown before it is asked for. Nothing is the Space's until Save, and a new Space is not
/// made before.
struct SpaceSheet: View {
    let tabs: TabsModel
    @State var draft: SpaceDraft
    @State private var pickingTint = false
    @State private var pickingIcon = false
    @FocusState private var naming: Bool
    @Environment(\.surfaceStyle) private var surface

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.l) {
            Text(draft.space == nil ? "New Space" : "Edit Space").font(Design.Text.title)
            Grid(
                alignment: .leadingFirstTextBaseline,
                horizontalSpacing: Design.Space.l,
                verticalSpacing: Design.Space.m
            ) {
                GridRow {
                    Text("Name").foregroundStyle(.secondary)
                    TextField("Name", text: $draft.name)
                        .textFieldStyle(.roundedBorder)
                        .focused($naming)
                        .onSubmit { tabs.save(draft) }
                        .accessibilityLabel("Space name")
                }
                GridRow {
                    Text("Color").foregroundStyle(.secondary)
                    field(action: { pickingTint = true }, label: "Space color") {
                        if let tint = draft.tint {
                            Circle().fill(Color(tint)).frame(width: 14, height: 14)
                            Text(tint.hex).monospaced()
                        } else {
                            Circle().strokeBorder(.secondary, lineWidth: 1).frame(width: 14, height: 14)
                            Text("None").foregroundStyle(.secondary)
                        }
                    }
                    .popover(isPresented: $pickingTint, arrowEdge: .trailing) {
                        VStack(alignment: .leading, spacing: Design.Space.m) {
                            IconColourRow(color: $draft.tint)
                            Text("Tints the window while it shows this Space.")
                                .font(Design.Text.detail)
                                .foregroundStyle(.secondary)
                        }
                        .padding(Design.Space.xl)
                        .solidPopoverBackground()
                    }
                }
                GridRow {
                    Text("Icon").foregroundStyle(.secondary)
                    field(action: { pickingIcon = true }, label: "Space icon") {
                        if let icon = draft.icon, PaneIconView.canShow(icon) {
                            PaneIconView(icon: icon)
                            Text(Self.name(of: icon)).lineLimit(1)
                        } else {
                            Text("None").foregroundStyle(.secondary)
                        }
                    }
                    .popover(isPresented: $pickingIcon, arrowEdge: .trailing) {
                        // Its colour is the symbol's own; the Space's colour is the field above.
                        IconPicker(icon: $draft.icon).padding(Design.Space.xl).frame(width: 340)
                            .solidPopoverBackground()
                    }
                }
            }
            profileRow
            HStack {
                Spacer()
                SwiftUI.Button("Cancel", role: .cancel) { tabs.spaceDraft = nil }.keyboardShortcut(.cancelAction)
                SwiftUI.Button("Save") { tabs.save(draft) }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!draft.canSave)
            }
        }
        .padding(Design.Space.xxl)
        .frame(width: 380)
        .onAppear { naming = true }
    }

    /// The profile, once there are several (the Space's own editor is one of the places a profile is chosen).
    @ViewBuilder private var profileRow: some View {
        if let profiles = tabs.spaces?.profiles, profiles.profiles.count > 1 {
            VStack(alignment: .leading, spacing: Design.Space.xs) {
                Picker("Profile", selection: $draft.profile) {
                    ForEach(profiles.profiles, id: \.profile.id) { profile in
                        Text(profile.profile.name).tag(profile.profile.isFirst ? Profile.ID?.none : profile.profile.id)
                    }
                }
                if draft.space != nil {
                    Text("With another profile its pages load again, signed in as that profile is.")
                        .font(Design.Text.detail)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// A field that is clicked, not typed in: what it holds, and a mark that it opens something.
    private func field<Content: View>(
        action: @escaping () -> Void,
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: Design.Space.s) {
                content()
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down").font(Design.Text.detail).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, Design.Space.m)
            .frame(height: 24)
            .frame(maxWidth: .infinity)
            .background(.quaternary, in: .rect(cornerRadius: Design.Radius.small(surface.layout)))
            .overlay {
                RoundedRectangle(cornerRadius: Design.Radius.small(surface.layout)).strokeBorder(.separator)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    static func name(of icon: PaneIcon) -> String {
        switch icon {
            case .symbol(let name, _): name
            // The emoji is beside it already.
            case .emoji: "Emoji"
        }
    }
}
