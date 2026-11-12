import SunsetShell
import SwiftUI

/// The find bar of a page (web step d): a small glass bar at the top right of its pane: the field with its options, "3 of 12", previous, next, Done.
/// Return goes to the next match, Shift-Return to the previous, Escape closes it and gives the page the keyboard.
struct WebFindBar: View {
    let content: WebContent
    @FocusState private var typing: Bool
    @Environment(\.surfaceStyle) private var surface

    private var find: PageFind { content.find }

    var body: some View {
        @Bindable var find = find
        HStack(spacing: Design.Space.s) {
            options
            TextField("Find on Page", text: $find.text)
                .textFieldStyle(.plain)
                .frame(width: Design.Width.findField)
                .fieldSurface()
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
            Group {
                SidebarIconButton(symbol: "chevron.up", help: "Previous (Shift-Cmd-G)") { find.search(backwards: true) }
                SidebarIconButton(symbol: "chevron.down", help: "Next (Cmd-G)") { find.search() }
            }
            .environment(\.sidebarButtonMetrics, BarButton.metrics(surface))
            Button("Done") { close() }.buttonStyle(.borderless)
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, Design.Space.s)
        .frame(height: Design.Size.bar)
        .blurSurface(surface.shape, shadow: .popover)
        .padding(Design.Space.l)
        .onAppear { typing = true }
        .onChange(of: find.focusRequest) { _, _ in typing = true }
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
