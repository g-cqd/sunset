/// A row of a list of choices (the command bar, the address field's list): what it shows and what it does (R1 web step c, the command bar study).
/// The first action is the one Return does; Cmd-Return does the second, Option-Return the third; Cmd-K lists them all.
package struct ChoiceRow: Identifiable {
    package let id: String
    package var glyph: PaneGlyph
    package var title: String
    package var subtitle: String?
    /// On the right: what kind of row it is, or a key that reaches it.
    package var accessory: String?
    package var actions: [ChoiceAction]

    package init(
        id: String,
        glyph: PaneGlyph,
        title: String,
        subtitle: String? = nil,
        accessory: String? = nil,
        actions: [ChoiceAction]
    ) {
        self.id = id
        self.glyph = glyph
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory
        self.actions = actions
    }
}
