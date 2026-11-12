import SwiftUI

/// The find bar of a page (web step d): a small glass bar at the top right of its pane: the field with its options, "3 of 12", previous, next, Done.
/// Return goes to the next match, Shift-Return to the previous, Escape closes it and gives the page the keyboard.
struct WebFindBar: View {
    let content: WebContent
    @FocusState private var typing: Bool

    private var find: PageFind { content.find }

    var body: some View {
        @Bindable var find = find
        HStack(spacing: 6) {
            options
            TextField("Find on Page", text: $find.text)
                .textFieldStyle(.plain)
                .frame(width: 170)
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
                .font(.caption.monospacedDigit())
                .foregroundStyle(find.count == 0 ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
                .fixedSize()
            Button {
                find.search(backwards: true)
            } label: {
                Image(systemName: "chevron.up")
            }
            .help("Previous (Shift-Cmd-G)")
            Button {
                find.search()
            } label: {
                Image(systemName: "chevron.down")
            }
            .help("Next (Cmd-G)")
            Button("Done") { close() }
        }
        .buttonStyle(.borderless)
        .disabled(false)
        .padding(.horizontal, 10)
        .frame(height: 34)
        .glassEffect(.regular, in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
        .padding(10)
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
