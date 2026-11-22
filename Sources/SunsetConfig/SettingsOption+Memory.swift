extension SettingsOption {
    /// Pages not on screen let go of their memory.
    static let memory: [Self] =
        [
            number(
                "web.unloadAfter",
                "Unload delay for hidden pages",
                "memory sleep unload discard hidden background tabs pages hours",
                \.web.unloadAfter,
                0 ... 168,
                step: 1,
                unit: "h",
                digits: 0
            )
            .noted(
                "A page loads again, where it was, when it is shown. Pages that play, capture, are pinned or kept awake "
                    + "stay; 0 never unloads by time."
            ),
            toggle(
                "web.unloadUnderPressure",
                "Unload hidden pages when memory runs short",
                "memory pressure unload discard low",
                \.web.unloadUnderPressure
            )
            .noted("The page hidden the longest goes first, one at a time, while macOS says memory is short.")
        ]
}
