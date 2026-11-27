import AppKit
import Foundation
import SunsetPane
import SunsetShell
import SunsetWeb

/// The rows of the command bar: the tabs that match, then what was typed as an address to go to or words to search (a path to a
/// file first: it opens), then the documents of the store that match, then pages of the history that match, then the engine's
/// suggestions. Each with its actions: the first is Return's, the second Cmd-Return's, the third Option-Return's.
@MainActor enum CommandBarRows {
    static func rows(
        _ bar: CommandBar,
        tabs: TabsModel,
        settings: WebSettings,
        suggestions: [String],
        history: HistoryStore? = AppHistory.shared
    ) -> [ChoiceRow] {
        let tabRows = purposeRows(bar, tabs: tabs)
        guard bar.purpose == .search else { return tabRows }
        // The other Spaces: by name, then their tabs (going to one changes Space).
        var rows = tabRows + SpaceRows.rows(bar, tabs: tabs)
        let chip = bar.engine.flatMap { name in settings.engines.first { $0.name == name } }
        let typed = bar.query.trimmingCharacters(in: .whitespaces)
        // Nothing of a scope that is off is offered: no address or search without the web, no file or stored document
        // without documents.
        let (web, documents) = (tabs.scopes.web, tabs.scopes.documents)
        let input: WebInput? =
            if !web { nil } else if let chip { typed.isEmpty ? nil : .search(chip, words: typed) } else {
                settings.input(typed)
            }
        // Recalled with the engine's keyword, so that the chip comes back with the words.
        let recall = chip.map { $0.keyword + " " + bar.query } ?? bar.query
        // A path to a file that is there is opened, not searched for: its row comes before what the web would do with it.
        if documents, chip == nil, let path = TypedPath.file(typed) { rows.append(DocumentRows.file(path, tabs: tabs)) }
        if let input { rows.append(Self.web(input, id: "typed", tabs: tabs, recall: recall)) }
        // The documents Sunset keeps, by title: after what was typed, so that Return does what it did.
        if documents, chip == nil { rows += documentRows(bar, typed: typed, tabs: tabs) }
        // A terminal or a document made as a page is: last, so that Return still does what it did.
        rows += newKindRows(bar, typed: chip == nil ? typed : nil, tabs: tabs)
        CommandRows.place(into: &rows, typed: chip == nil ? typed : nil, tabs: tabs)
        guard web else { return rows }
        if chip == nil {
            let visited = (history?.suggestions(for: typed) ?? []).filter { $0.url != input?.url?.absoluteString }
            rows += visited.compactMap { entry in
                guard let url = URL(string: entry.url) else { return nil }
                var row = Self.web(
                    .address(url, guessed: false),
                    id: "visited " + entry.url,
                    tabs: tabs,
                    recall: entry.url
                )
                row.glyph = .symbol("clock")
                row.title = entry.title.isEmpty ? entry.url : entry.title
                row.subtitle = AddressChoice.shortAddress(entry.url)
                row.accessory = "History"
                return row
            }
        }
        let engine: SearchEngine = if case .search(let chosen, _)? = input { chosen } else { chip ?? settings.engine }
        rows += suggestions.map {
            Self.web(.search(engine, words: $0), id: "suggestion " + $0, tabs: tabs, recall: $0, suggested: true)
        }
        return rows
    }

    /// The tabs that match; opened to make a new tab (Shift-Cmd-T), its kinds instead.
    private static func purposeRows(_ bar: CommandBar, tabs: TabsModel) -> [ChoiceRow] {
        guard bar.purpose == .newTab else { return tabs.barResults(bar).map { tab($0, bar: bar, tabs: tabs) } }
        return NewKindChoices.newTab(typed: bar.query, scopes: tabs.scopes).map { newKind($0, bar: bar, tabs: tabs) }
    }

    /// The documents of the store and the files opened lately whose title matches; not a file twice when its path is
    /// what was typed.
    private static func documentRows(_ bar: CommandBar, typed: String, tabs: TabsModel) -> [ChoiceRow] {
        let typedFile = TypedPath.file(typed)
        return tabs.barDocuments(bar)
            .compactMap { document in
                guard let file = document.file else { return DocumentRows.stored(document, tabs: tabs) }
                return file == typedFile ? nil : DocumentRows.file(file, tabs: tabs)
            }
    }

    /// The new terminal and document rows for `typed` (none with an engine's chip: nil).
    private static func newKindRows(_ bar: CommandBar, typed: String?, tabs: TabsModel) -> [ChoiceRow] {
        guard let typed else { return [] }
        return NewKindChoices.kinds(typed: typed, forNewPage: bar.forNewPage, scopes: tabs.scopes)
            .map { newKind($0, bar: bar, tabs: tabs) }
    }

    /// A new terminal or document. From a new tab's bar it takes the empty page's place, as if that tab had been of its
    /// kind; from elsewhere it is a tab of its own.
    private static func newKind(_ kind: NewKindChoices.Kind, bar: CommandBar, tabs: TabsModel) -> ChoiceRow {
        let (title, glyph) =
            switch kind {
                case .terminal: ("New Terminal", "terminal")
                case .page: ("New Web Page", "globe")
                case .document: ("New Document", "doc.text")
            }
        let make: @MainActor () -> Void = {
            let blank = bar.forNewPage && tabs.selectedContent?.isBlankPage == true ? tabs.workspace.selectedItem : nil
            tabs.bar = nil
            if let blank { tabs.close(item: blank.id) }
            switch kind {
                case .terminal: AppActions.shared.newTab(kind: PaneDescriptor.terminal(directory: nil))
                case .page: AppActions.shared.newTab(kind: PaneContentKinds.newPage)
                case .document: AppActions.shared.newDocument()
            }
        }
        return ChoiceRow(
            id: "new \(title)",
            glyph: .symbol(glyph),
            title: title,
            accessory: "Tab",
            actions: [ChoiceAction(title, symbol: "plus.square", perform: make)]
        )
    }

    private static func tab(_ item: Workspace.Item, bar: CommandBar, tabs: TabsModel) -> ChoiceRow {
        let model = tabs.contents[item.focused]
        // Not loaded (a tab of the last session that waits): what it would start from.
        let saved = model == nil ? tabs.pendingDescriptor(item.focused) : nil
        let index = tabs.workspace.items.firstIndex { $0.id == item.id } ?? 99
        let last = index == tabs.workspace.count - 1
        let accessory =
            item.isSplit
            ? "\(item.panes.count) panes" : (index < 8 ? "\u{2318}\(index + 1)" : (last ? "\u{2318}9" : nil))
        return ChoiceRow(
            id: "tab \(item.id)",
            glyph: TabLabel.rowGlyph(model: model, saved: saved),
            title: TabLabel.rowTitle(model: model, saved: saved, name: tabs.custom(for: item).name),
            subtitle: TabLabel.rowSubtitle(model: model, saved: saved),
            accessory: accessory,
            actions: tabActions(item.id, bar: bar, tabs: tabs)
        )
    }

    private static func tabActions(_ id: Workspace.ItemID, bar: CommandBar, tabs: TabsModel) -> [ChoiceAction] {
        if case .splitWith = bar.purpose {
            return [ChoiceAction("Split With This Tab", symbol: "rectangle.split.2x1") { tabs.accept(id, in: bar) }]
        }
        var actions = [ChoiceAction("Show Tab", symbol: "arrow.right.square") { tabs.accept(id, in: bar) }]
        if let shown = tabs.workspace.selectedPane, tabs.workspace.item(containing: shown)?.id != id {
            actions.append(
                ChoiceAction("Split Right With This Tab", symbol: "rectangle.split.2x1") {
                    tabs.bar = nil
                    tabs.change { $0.drop(item: id, onto: shown, edge: .right) }
                }
            )
            actions.append(
                ChoiceAction("Split Down With This Tab", symbol: "rectangle.split.1x2") {
                    tabs.bar = nil
                    tabs.change { $0.drop(item: id, onto: shown, edge: .bottom) }
                }
            )
        }
        actions += [
            ChoiceAction("Rename\u{2026}", symbol: "pencil") {
                tabs.bar = nil
                tabs.beginRename(item: id)
            },
            ChoiceAction("Add to Favorites", symbol: "star") {
                tabs.bar = nil
                tabs.addToFavorites([.tab(id)])
            },
            ChoiceAction("Close Tab", symbol: "xmark") {
                tabs.bar = nil
                tabs.close(item: id)
            }
        ]
        return ChoiceAction.keyed(actions)
    }

    /// A row that goes to an address or searches: in the focused page (from a terminal: a new page tab), in a new tab, split right, or copied.
    private static func web(
        _ input: WebInput,
        id: String,
        tabs: TabsModel,
        recall: String,
        suggested: Bool = false
    ) -> ChoiceRow {
        let (title, accessory, glyph): (String, String, PaneGlyph) =
            switch input {
                case .address(let url, _): ("Go to \(url.absoluteString)", "Address", .symbol("globe"))
                case .search(let engine, let words):
                    suggested
                        ? (words, engine.name, .symbol("magnifyingglass"))
                        : (
                            "Search \(engine.name) for \u{201C}\(words)\u{201D}", engine.name,
                            .symbol("magnifyingglass")
                        )
            }
        return ChoiceRow(
            id: id,
            glyph: glyph,
            title: title,
            accessory: accessory,
            actions: webActions(input, tabs: tabs, recall: recall)
        )
    }

    private static func webActions(_ input: WebInput, tabs: TabsModel, recall: String) -> [ChoiceAction] {
        func done() {
            tabs.bar = nil
            // Nothing typed in a private context is kept, not even for this session's recall.
            let privateHere = tabs.isPrivateWindow || (tabs.selectedContent as? WebContent)?.isPrivate == true
            guard !privateHere else { return }
            tabs.barRecall.removeAll { $0 == recall }
            tabs.barRecall.append(recall)
        }
        let inPage = tabs.selectedContent is WebContent
        let here = ChoiceAction(inPage ? "Open Here" : "Open in New Tab", symbol: "arrow.up.right.square") {
            done()
            WebGo.open(input, in: tabs, place: inPage ? .here : .newTab)
        }
        let newTab = ChoiceAction("Open in New Tab", symbol: "plus.square") {
            done()
            WebGo.open(input, in: tabs, place: .newTab)
        }
        let split = ChoiceAction("Open in Split Right", symbol: "rectangle.split.2x1") {
            done()
            WebGo.open(input, in: tabs, place: .splitRight)
        }
        let copy = ChoiceAction("Copy Address", symbol: "doc.on.doc", key: nil) {
            tabs.bar = nil
            Clipboard.copyAndSay(input.url?.absoluteString, isLink: true, what: "Copied the address")
        }
        return ChoiceAction.keyed(inPage ? [here, newTab, split, copy] : [here, split, copy])
    }
}
