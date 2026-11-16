import SunsetPane
import SunsetShell

/// The command bar's rows for the other Spaces (R4): a Space by its name, and a tab of another Space, which is gone to
/// there.
@MainActor enum SpaceRows {
    static func rows(_ bar: CommandBar, tabs: TabsModel) -> [ChoiceRow] {
        let spaces = tabs.barSpaces(bar)
            .map { space in
                ChoiceRow(
                    id: "space \(space.space.id)",
                    glyph: glyph(space.space),
                    title: space.space.name,
                    subtitle: space.tabs.count == 1 ? "1 tab" : "\(space.tabs.count) tabs",
                    accessory: "Space",
                    actions: [
                        ChoiceAction("Show Space", symbol: "arrow.right.square") {
                            tabs.bar = nil
                            tabs.show(spaceInOrder: space)
                        }
                    ]
                )
            }
        let elsewhere = tabs.barTabsElsewhere(bar)
            .map { found in
                let model = found.space.contents[found.item.focused]
                return ChoiceRow(
                    id: "tab \(found.item.id)",
                    glyph: model?.glyph ?? .symbol("terminal"),
                    title: found.item.customTitle ?? model?.title ?? "Sunset",
                    subtitle: model?.detail.map(TabLabel.shortened),
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

    private static func glyph(_ space: Space) -> PaneGlyph {
        switch space.icon {
            case .symbol(let name, _)?: .symbol(name)
            case .emoji(let emoji)?: .initial(emoji)
            case nil: .symbol("square.stack")
        }
    }
}
