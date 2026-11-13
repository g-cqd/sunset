extension Design {
    /// Inside a bar group (`View.barGroup`): its controls fill it, the glass no rim around them; the spacing goes inside the fields,
    /// before their text (owner, 2026-11-13: variant D of research/blur §7k).
    package enum BarGroup {
        /// The height of a control in a group, its corner radius half of it: the group's own (capsules, the same shape).
        package static let control = Size.bar
        /// A field's text from its rounded end: the field's own spacing and the half of the height it gained.
        package static let fieldPadding = Space.m + (control - Size.field) / 2
    }
}
