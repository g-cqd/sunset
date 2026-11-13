import AemiSDR
import SunsetShell
import SwiftUI

/// The find bar of a page (web step d), the window bar's look: a field (its options, what is looked for, "3 of 12") and previous, next, Done.
/// Return goes to the next match, Shift-Return to the previous, Escape closes it and gives the page the keyboard.
struct WebFindBar: View {
    let content: WebContent
    /// Its blur falls down from the top edge (in the window bar at the bottom: up).
    var atTop = true
    @FocusState private var typing: Bool
    @Environment(\.surfaceStyle) private var surface

    private var find: PageFind { content.find }

    /// Its groups only: its host places them, in a glass container whose `barGroupBlurs` draws their blurs (its pane, or the
    /// window bar's row).
    var body: some View {
        HStack(spacing: Design.Space.m) {
            field
                .padding(.horizontal, Design.Space.s)
                .frame(height: Design.Size.bar)
                .barGroup(margin: Design.Space.m, top: atTop)
            buttons
                .padding(.horizontal, Design.Space.s)
                .frame(height: Design.Size.bar)
                .barGroup(margin: Design.Space.m, top: atTop)
        }
        .onAppear { typing = true }
        .onChange(of: find.focusRequest) { _, _ in typing = true }
    }

    /// The options, what is looked for and how many there are, in one field as the address is.
    private var field: some View {
        @Bindable var find = find
        return HStack(spacing: Design.Optical.fieldGlyphToText) {
            options
            TextField("Find on Page", text: $find.text)
                .textFieldStyle(.plain)
                .focused($typing)
                .onChange(of: find.text) { _, _ in find.restart() }
                .onKeyPress(.return, phases: .down) { press in
                    find.search(backwards: press.modifiers.contains(.shift))
                    return .handled
                }
                .onKeyPress(.escape) {
                    close()
                    return .handled
                }
            Text(find.status)
                .font(Design.Text.detail.monospacedDigit())
                .foregroundStyle(find.count == 0 ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
                .fixedSize()
        }
        .frame(width: Design.Width.findField)
        .fieldSurface()
        .clipShape(Capsule())
    }

    /// Previous, next and Done: icon buttons as back, forward and reload are.
    private var buttons: some View {
        HStack(spacing: Design.Space.xs) {
            SidebarIconButton(symbol: "chevron.up", help: "Previous (Shift-Cmd-G)") { find.search(backwards: true) }
            SidebarIconButton(symbol: "chevron.down", help: "Next (Cmd-G)") { find.search() }
            SidebarIconButton(symbol: "xmark", help: "Done (Escape)") { close() }
        }
        .environment(\.sidebarButtonMetrics, BarButton.metrics(surface, radius: Design.Size.field / 2))
    }

    private var options: some View {
        @Bindable var find = find
        return Menu {
            Toggle("Match Case", isOn: $find.matchCase)
            Toggle("Starts With", isOn: $find.startsWith)
        } label: {
            Image(systemName: "magnifyingglass")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.visible)
        .fixedSize()
        .onChange(of: find.matchCase) { _, _ in find.search() }
        .onChange(of: find.startsWith) { _, _ in find.search() }
    }

    private func close() {
        find.close()
        content.focusPage()
    }
}
