extension ConfigurationPatcher {
    /// The settings of before the look settings had a value per scheme (design 0009), read and then taken out.
    static let formerValueKeys = ["appearance.tint.light", "appearance.tint.lightAlpha", "web.pageScheme"]

    /// `text` written with the present keys and values, as it was otherwise: the settings at their former keys moved to
    /// the file's (`movingFormerKeys`), and the former values (`formerValueKeys`, an opaque or filled window) as the look
    /// settings say them now. Nil when it has nothing of before, or cannot be read.
    public static func upgraded(_ text: String) -> String? {
        guard let parsed = try? ConfigurationParser.parse(text), parsed.hasFormerKeys || parsed.hasFormerValues else {
            return nil
        }
        var current = text
        if parsed.hasFormerKeys {
            guard let moved = movingFormerKeys(current) else { return nil }
            current = moved
        }
        guard parsed.hasFormerValues else { return current }
        return presentValues(current)
    }

    /// `text` with every look setting and `appearance.contentFollows` written as they are read, the former keys taken out.
    private static func presentValues(_ text: String) -> String? {
        guard let parsed = try? ConfigurationParser.parse(text) else { return nil }
        let literals = ConfigurationWriter.literals(for: parsed.configuration)
        let keys = Configuration.schemeKeys + [SettingsOption.contentFollowsKey]
        let values = Dictionary(
            uniqueKeysWithValues: keys.compactMap { key in literals[key].map { (FileKeys.file(key), $0) } }
        )
        return patch(text, set: values).flatMap { removing($0, paths: formerValueKeys.map(FileKeys.file)) }
    }
}
