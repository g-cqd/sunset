import AppKit
import SunsetPane
import SunsetShell
import SunsetWeb

/// The rows of the command bar (the command bar study, web step c): the tabs that match, then what was typed as an address to go to or words to
/// search, then the engine's suggestions. Each with its actions: the first is Return's, the second Cmd-Return's, the third Option-Return's.
@MainActor enum CommandBarRows {
    static func rows(_ bar: CommandBar, tabs: TabsModel, settings: WebSettings, suggestions: [String]) -> [ChoiceRow] {
        let tabRows = tabs.barResults(bar).map { tab($0, bar: bar, tabs: tabs) }
        guard bar.purpose == .search else { return tabRows }
        var rows = tabRows
        let chip = bar.engine.flatMap { name in settings.engines.first { $0.name == name } }
        let typed = bar.query.trimmingCharacters(in: .whitespaces)
        let input: WebInput? =
            if let chip { typed.isEmpty ? nil : .search(chip, words: typed) } else { settings.input(typed) }
        if let input { rows.append(web(input, id: "typed", tabs: tabs, recall: bar.query)) }
        let engine = chip ?? settings.engine
        rows += suggestions.map {
            web(.search(engine, words: $0), id: "suggestion " + $0, tabs: tabs, recall: $0, suggested: true)
        }
        return rows
    }

    private static func tab(_ item: Workspace.Item, bar: CommandBar, tabs: TabsModel) -> ChoiceRow {
        let model = tabs.contents[item.focused]
        let index = tabs.workspace.items.firstIndex { $0.id == item.id } ?? 99
        let last = index == tabs.workspace.count - 1
        let accessory =
            item.isSplit
            ? "\(item.panes.count) panes" : (index < 8 ? "\u{2318}\(index + 1)" : (last ? "\u{2318}9" : nil))
        return ChoiceRow(
            id: "tab \(item.id)",
            glyph: model?.glyph ?? .symbol("terminal"),
            title: tabs.custom(for: item).name ?? model?.title ?? "Sunset",
            subtitle: model?.detail.map(TabLabel.shortened),
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
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(input.url?.absoluteString ?? "", forType: .string)
        }
        return ChoiceAction.keyed(inPage ? [here, newTab, split, copy] : [here, split, copy])
    }
}
