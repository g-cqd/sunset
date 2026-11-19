import AppKit
package import SunsetPane
package import SwiftUI

/// Picks an icon (R3 step c; the owner, 2026-11-17: fast, and "emojis as well as symbols"): a search over the system's
/// symbols and emoji, the symbols by category, the emoji in one list, a colour for a symbol, and no icon. What is typed
/// finds symbols first, then emoji. The catalogs are kept between openings (`IconLibrary`), what is found is kept until
/// the search changes, and the grid draws itself (`IconGridView`).
package struct IconPicker: View {
    @Binding var icon: PaneIcon?
    /// Whether the colours are offered here; not when the form around the picker has a field for them.
    var showsColours = true
    /// What the way back to no icon of its own says (a page: "Use Site Icon", roadmap 0036 A).
    var clearTitle = "No Icon"
    @State private var catalogs: IconCatalogs? = IconLibrary.shared.ready
    @State private var query = ""
    @State private var showsEmoji = false
    @State private var category = "all"
    @State private var results: [IconChoice] = []
    @State private var generation = 0
    @State private var hovered: IconChoice?
    @State private var typedEmoji = ""
    @FocusState private var emojiFocused: Bool
    @Environment(\.accent) private var accent
    @Environment(\.surfaceStyle) private var surface

    /// Colours that read in light and dark: red, orange, yellow, green, teal, blue, purple, pink, grey.
    static let presets: [IconColor] = [
        .init(red: 0xFF, green: 0x45, blue: 0x3A), .init(red: 0xFF, green: 0x9F, blue: 0x0A),
        .init(red: 0xFF, green: 0xD6, blue: 0x0A),
        .init(red: 0x30, green: 0xD1, blue: 0x58), .init(red: 0x40, green: 0xC8, blue: 0xE0),
        .init(red: 0x0A, green: 0x84, blue: 0xFF),
        .init(red: 0xBF, green: 0x5A, blue: 0xF2), .init(red: 0xFF, green: 0x37, blue: 0x5F),
        .init(red: 0x98, green: 0x98, blue: 0x9D)
    ]

    package init(icon: Binding<PaneIcon?>, showsColours: Bool = true, clearTitle: String = "No Icon") {
        _icon = icon
        self.showsColours = showsColours
        self.clearTitle = clearTitle
    }

    private var searching: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var chosen: String? {
        switch icon {
            case .symbol(let name, _)?: name
            case .emoji(let emoji)?: emoji
            case nil: nil
        }
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.m) {
            TextField("Search symbols and emoji", text: $query).textFieldStyle(.roundedBorder)
            Picker("Kind", selection: $showsEmoji) {
                Text("Symbols").tag(false)
                Text("Emoji").tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .disabled(searching)
            if let catalogs {
                if !showsEmoji { categories(catalogs.symbols) }
                IconGrid(
                    items: results,
                    generation: generation,
                    chosen: chosen,
                    accent: accent.color,
                    pick: { icon = $0.icon(keeping: icon?.color) },
                    hover: { hovered = $0 }
                )
                .frame(height: showsEmoji ? 220 + 22 + Design.Space.m : 220)
                .overlay { if results.isEmpty { Text("Nothing found").foregroundStyle(.secondary) } }
            } else {
                ProgressView().frame(maxWidth: .infinity, minHeight: 220)
            }
            // The name of the one under the pointer, else of the one chosen.
            Text(hovered?.label ?? results.first { $0.id == chosen }?.label ?? " ")
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if showsColours { colours }
            HStack {
                moreEmoji
                Spacer()
                SwiftUI.Button(clearTitle) { icon = nil }.disabled(icon == nil)
            }
        }
        .onChange(of: query) { _, _ in refresh() }
        .onChange(of: showsEmoji) { _, _ in refresh() }
        .onChange(of: category) { _, _ in refresh() }
        .task {
            IconLibrary.shared.opened()
            if case .emoji? = icon { showsEmoji = true }
            if catalogs == nil { catalogs = await IconLibrary.shared.catalogs() }
            refresh()
        }
        .onDisappear { IconLibrary.shared.closed() }
    }

    /// What the grid shows, found once for what is typed and chosen: symbols then emoji for a search, else the kind shown.
    private func refresh() {
        guard let catalogs else { return }
        let typed = query.trimmingCharacters(in: .whitespaces)
        if typed.isEmpty {
            results =
                showsEmoji
                ? catalogs.emoji.emoji.map(IconChoice.init)
                : catalogs.symbols.search("", in: category).map(IconChoice.init)
        } else {
            let emoji = catalogs.emoji.search(typed)
            // The loose match (letters in order) is for a search that finds nothing else at all.
            let symbols = catalogs.symbols.search(typed, loosely: emoji.isEmpty)
            results = symbols.map(IconChoice.init) + emoji.map(IconChoice.init)
        }
        generation += 1
        hovered = nil
    }

    private func categories(_ catalog: SymbolCatalog) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Design.Space.hair) {
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
                        in: .rect(cornerRadius: Design.Radius.small(surface.layout))
                    )
                    .help(entry.key)
                }
            }
        }
        .bouncesOnlyWhenScrolling()
        .opacity(searching ? Design.Fill.notApplicable : 1)
    }

    /// A colour is for a symbol only (R3): with an emoji or no icon, the row is dimmed.
    private var colours: some View {
        let isSymbol = if case .symbol? = icon { true } else { false }
        return IconColourRow(color: Binding(get: { icon?.color }, set: { icon = icon?.colored($0) }))
            .disabled(!isSymbol)
            .opacity(isSymbol ? 1 : Design.Fill.notApplicable)
    }

    /// The system's Character Viewer, for what the list has not (skin tones): it types into this field, which becomes the icon.
    private var moreEmoji: some View {
        HStack(spacing: Design.Space.xs) {
            TextField("", text: $typedEmoji)
                .frame(width: 34)
                .focused($emojiFocused)
                .onChange(of: typedEmoji) { _, typed in
                    guard let first = typed.first else { return }
                    icon = .emoji(String(first))
                    typedEmoji = ""
                }
                .accessibilityLabel("Emoji from the Character Viewer")
            SwiftUI.Button("More Emoji\u{2026}") {
                emojiFocused = true
                NSApp.orderFrontCharacterPalette(nil)
            }
            .help("Opens the system's Character Viewer; the emoji you pick becomes the icon")
        }
    }
}
