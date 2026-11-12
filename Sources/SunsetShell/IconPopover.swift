import AppKit
import SunsetPane
package import SwiftUI

/// The icon of a tab, an entry or a folder (R3 step c, owner's answers): a searchable grid of the system's symbols by category, the system's Character
/// Viewer for an emoji, preset colours and a colour well for a symbol, and a way back to the row's own picture. The catalog is read when the popover opens.
package struct IconPopover: View {
    let tabs: TabsModel
    let row: RowTarget
    @State private var catalog: SymbolCatalog?
    @Environment(\.accent) private var accent
    @State private var query = ""
    @State private var category = "all"
    @State private var emoji = ""
    @FocusState private var emojiFocused: Bool

    /// Colours that read in light and dark: red, orange, yellow, green, teal, blue, purple, pink, grey.
    static let presets: [IconColor] = [
        .init(red: 0xFF, green: 0x45, blue: 0x3A), .init(red: 0xFF, green: 0x9F, blue: 0x0A),
        .init(red: 0xFF, green: 0xD6, blue: 0x0A),
        .init(red: 0x30, green: 0xD1, blue: 0x58), .init(red: 0x40, green: 0xC8, blue: 0xE0),
        .init(red: 0x0A, green: 0x84, blue: 0xFF),
        .init(red: 0xBF, green: 0x5A, blue: 0xF2), .init(red: 0xFF, green: 0x37, blue: 0x5F),
        .init(red: 0x98, green: 0x98, blue: 0x9D)
    ]

    package init(tabs: TabsModel, row: RowTarget) {
        self.tabs = tabs
        self.row = row
    }

    private var icon: PaneIcon? { tabs.icon(of: row) }

    package var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Search symbols", text: $query).textFieldStyle(.roundedBorder)
            if let catalog {
                categories(catalog)
                grid(catalog.search(query, in: query.isEmpty ? category : nil))
            } else {
                ProgressView().frame(maxWidth: .infinity, minHeight: 220)
            }
            colours
            HStack {
                emojiButton
                Spacer()
                SwiftUI.Button("No Icon") { tabs.setIcon(nil, for: row) }.disabled(icon == nil)
            }
        }
        .padding(Design.Space.xl)
        .frame(width: 340)
        .task { catalog = await Task.detached(priority: .userInitiated) { SymbolCatalog.load() }.value }
    }

    private func categories(_ catalog: SymbolCatalog) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(catalog.categories, id: \.key) { entry in
                    SwiftUI.Button {
                        category = entry.key
                    } label: {
                        Image(systemName: entry.icon).frame(width: 24, height: 22)
                    }
                    .buttonStyle(.borderless)
                    .background(
                        category == entry.key
                            ? AnyShapeStyle(accent.color.opacity(Design.Fill.target)) : AnyShapeStyle(Color.clear),
                        in: .rect(cornerRadius: 4)
                    )
                    .help(entry.key)
                }
            }
        }
        .opacity(query.isEmpty ? 1 : 0.4)
    }

    private func grid(_ symbols: [SymbolCatalog.Symbol]) -> some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(30), spacing: 4), count: 9), spacing: 4) {
                ForEach(symbols) { symbol in
                    SwiftUI.Button {
                        tabs.setIcon(.symbol(symbol.name, color: icon?.color), for: row)
                    } label: {
                        Image(systemName: symbol.name)
                            .font(.system(size: Design.Symbol.bar))
                            .frame(width: 30, height: 28)
                            .background(
                                chosen(symbol.name)
                                    ? AnyShapeStyle(accent.color.opacity(Design.Fill.markedHover))
                                    : AnyShapeStyle(Color.clear),
                                in: .rect(cornerRadius: 5)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(symbol.name)
                }
            }
        }
        .frame(height: 220)
        .overlay { if symbols.isEmpty { Text("No symbol found").foregroundStyle(.secondary) } }
    }

    private func chosen(_ name: String) -> Bool { if case .symbol(name, _)? = icon { true } else { false } }

    /// A colour is for a symbol only (R3): with an emoji or no icon, the row is dimmed.
    private var colours: some View {
        let isSymbol = if case .symbol? = icon { true } else { false }
        return HStack(spacing: 6) {
            ForEach(Self.presets, id: \.self) { color in
                Circle()
                    .fill(Color(color))
                    .frame(width: 16, height: 16)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                .primary.opacity(icon?.color == color ? Design.Fill.accentPressed : 0),
                                lineWidth: 2
                            )
                    }
                    .onTapGesture { tabs.setIcon(icon?.colored(color), for: row) }
            }
            ColorPicker(
                "",
                selection: Binding(
                    get: { icon?.color.map { Color($0) } ?? .secondary },
                    set: { if let color = IconColor($0) { tabs.setIcon(icon?.colored(color), for: row) } }
                ),
                supportsOpacity: false
            )
            .labelsHidden()
            SwiftUI.Button("None") { tabs.setIcon(icon?.colored(nil), for: row) }.buttonStyle(.borderless)
                .font(Design.Text.detail)
        }
        .disabled(!isSymbol)
        .opacity(isSymbol ? 1 : 0.4)
    }

    /// The system's Character Viewer types its emoji into this field, which becomes the icon.
    private var emojiButton: some View {
        HStack(spacing: 4) {
            TextField("", text: $emoji)
                .frame(width: 34)
                .focused($emojiFocused)
                .onChange(of: emoji) { _, typed in
                    guard let first = typed.first else { return }
                    tabs.setIcon(.emoji(String(first)), for: row)
                    emoji = ""
                }
            SwiftUI.Button("Emoji\u{2026}") {
                emojiFocused = true
                NSApp.orderFrontCharacterPalette(nil)
            }
            .help("Opens the system's Character Viewer; the emoji you pick becomes the icon")
        }
    }
}
