/// A part of a settings page (the owner's note n13): a group of options under a heading, or one list of things the person
/// added (search engines, sites, profiles) with its heading and its note under it. The page draws each as a section.
public struct SettingsBlock: Sendable, Identifiable {
    /// The heading: the group's, or the list's own title; nil for the options of a topic that are not grouped.
    public let title: String?
    public let options: [SettingsOption]
    /// The block is one list (`SettingsControl.Custom.isList`), first, then the options grouped under its title; its note goes
    /// under it.
    public let isList: Bool

    public var id: String { options.first?.id ?? title ?? "" }

    /// The options in order, as the page shows them.
    public static func blocks(_ options: [SettingsOption]) -> [Self] {
        var blocks: [Self] = []
        for option in options {
            if option.isList {
                blocks.append(Self(title: option.title, options: [option], isList: true))
            } else if let last = blocks.last, last.title == option.group,
                !last.isList || option.group != nil
            {
                blocks[blocks.count - 1] = Self(
                    title: last.title,
                    options: last.options + [option],
                    isList: last.isList
                )
            } else {
                blocks.append(Self(title: option.group, options: [option], isList: false))
            }
        }
        return blocks
    }
}
