package import SwiftUI

/// Shared capsule find bar chrome used by both `WebFindBar` (web pages) and `TerminalFindBar` (terminal scrollback,
/// T-3 / roadmap 0026): options menu, text field, live status badge, and Previous / Next / Done buttons.
package struct FindBarView<Model: FindBarModel>: View {
    @Bindable package var model: Model
    package var atTop = true

    @FocusState private var typing: Bool
    @Environment(\.surfaceStyle) private var surface

    package init(model: Model, atTop: Bool = true) {
        self.model = model
        self.atTop = atTop
    }

    package var body: some View {
        HStack(spacing: Design.Space.m) {
            field
                .frame(height: Design.Size.bar)
                .barGroup(margin: Design.Space.m, top: atTop)
            buttons
                .frame(height: Design.Size.bar)
                .barGroup(margin: Design.Space.m, top: atTop)
        }
        .onAppear { typing = true }
        .onChange(of: model.focusRequest) { _, _ in typing = true }
        .onChange(of: model.matchCase) { _, _ in model.findOptionsChanged() }
        .onChange(of: model.secondaryOption) { _, _ in model.findOptionsChanged() }
    }

    private var field: some View {
        HStack(spacing: Design.Optical.fieldGlyphToText) {
            optionsMenu
            TextField(model.findPrompt, text: $model.text)
                .textFieldStyle(.plain)
                .focused($typing)
                .onChange(of: model.text) { _, _ in model.findTextChanged() }
                .onKeyPress(.return, phases: .down) { press in
                    model.findStep(backwards: press.modifiers.contains(.shift))
                    return .handled
                }
                .onKeyPress(.escape) {
                    model.findClose()
                    return .handled
                }
            Text(model.status)
                .font(Design.Text.detail.monospacedDigit())
                .foregroundStyle(model.isFindError ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
                .fixedSize()
        }
        .frame(width: Design.Width.findField)
        .fieldSurface()
        .clipShape(Capsule())
    }

    private var optionsMenu: some View {
        Menu {
            Toggle(model.secondaryOptionTitle, isOn: $model.secondaryOption)
            Toggle("Match Case", isOn: $model.matchCase)
        } label: {
            Image(systemName: model.findIconSymbol)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .tint(.secondary)
        .foregroundStyle(.secondary)
        .fixedSize()
    }

    private var buttons: some View {
        HStack(spacing: Design.Space.xs) {
            SidebarIconButton(symbol: "chevron.up", help: "Previous (Shift-Cmd-G)") { model.findStep(backwards: true) }
            SidebarIconButton(symbol: "chevron.down", help: "Next (Cmd-G)") { model.findStep(backwards: false) }
            SidebarIconButton(symbol: "xmark", help: "Done (Escape)") { model.findClose() }
        }
        .padding(.horizontal, Design.BarGroup.buttonInset)
        .environment(\.sidebarButtonMetrics, BarButton.group(surface))
    }
}
