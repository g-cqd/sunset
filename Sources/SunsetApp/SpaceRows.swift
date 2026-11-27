import SunsetPane
import SunsetShell

/// The command bar's rows for the other Spaces: a Space by its name, and a tab of another Space, which is gone to
/// there.
@MainActor enum SpaceRows {
    static func rows(_ bar: CommandBar, tabs: TabsModel) -> [ChoiceRow] {
        let spaces = tabs.barSpaces(bar)
            .map { space in
                row(space, id: "space", action: "Show Space") {
                    tabs.bar = nil
                    tabs.show(spaceInOrder: space)
                }
            }
        let elsewhere = tabs.barTabsElsewhere(bar)
            .map { found in
                let model = found.space.contents[found.item.focused]
                let saved = model == nil ? found.space.pending[found.item.focused] : nil
                return ChoiceRow(
                    id: "tab \(found.item.id)",
                    glyph: TabLabel.rowGlyph(model: model, saved: saved),
                    title: TabLabel.rowTitle(model: model, saved: saved, name: found.item.customTitle),
                    subtitle: TabLabel.rowSubtitle(model: model, saved: saved),
                    accessory: found.space.space.name,
                    actions: [
                        ChoiceAction("Show Tab in \(found.space.space.name)", symbol: "arrow.right.square") {
                            tabs.show(found.item.id, in: found.space)
                        }
                    ]
                )
            }
        return spaces + elsewhere
    }

    /// The Spaces the tab `item` can move to (Move Tab to Space…): chosen, it goes there, still running.
    static func moveTargets(_ item: Workspace.ItemID, bar: CommandBar, tabs: TabsModel) -> [ChoiceRow] {
        tabs.moveTargets(bar)
            .map { space in
                row(space, id: "move", action: "Move Tab Here") {
                    tabs.bar = nil
                    tabs.move(rows: [.tab(item)], to: space)
                }
            }
    }

    /// A Space as a row: its name, its glyph and how many tabs it has; `action` is what Return does.
    private static func row(
        _ space: SpaceModel,
        id: String,
        action: String,
        perform: @escaping @MainActor () -> Void
    ) -> ChoiceRow {
        ChoiceRow(
            id: "\(id) \(space.space.id)",
            glyph: glyph(space.space),
            title: space.space.name,
            subtitle: space.tabs.count == 1 ? "1 tab" : "\(space.tabs.count) tabs",
            accessory: "Space",
            actions: [ChoiceAction(action, symbol: "arrow.right.square", perform: perform)]
        )
    }

    private static func glyph(_ space: Space) -> PaneGlyph {
        switch space.icon {
            case .symbol(let name, _)?: .symbol(name)
            case .emoji(let emoji)?: .initial(emoji)
            case nil: .symbol("square.stack")
        }
    }
}
