import SunsetMetrics

/// What a new tab is, and what opens with none (the owner's notes n70, n74).
extension SettingsOption {
    static let newTabs: [Self] =
        [
            choice(
                "tabs.newTab",
                "New tab with Command-T",
                "new tab command t kind terminal web page document default",
                \.tabs.newTab,
                [
                    (.focused, "Focused tab's kind"), (.terminal, "Terminal"),
                    (.web, "Web page"), (.document, "Document")
                ]
            )
            .noted("Command-Shift-T asks which kind each time."),
            choice(
                "tabs.start",
                "Opening with no tab",
                "start launch open empty startup first tab window terminal page address document file",
                \.tabs.start,
                [
                    (.nothing, "Nothing"), (.terminal, "Terminal"), (.web, "Web page"),
                    (.address, "Address"), (.newDocument, "New document"), (.file, "Document file")
                ]
            )
            .noted("When Sunset opens, or a window opens on an empty Space."),
            text(
                "tabs.startAddress",
                "Address",
                "start launch url page home",
                \.tabs.startAddress,
                prompt: "example.com"
            )
            .shown { $0.tabs.start == .address },
            text(
                "tabs.startFile",
                "Document file",
                "start launch file path markdown",
                \.tabs.startFile,
                prompt: "~/Notes/today.md"
            )
            .shown { $0.tabs.start == .file },
            text(
                "tabs.startProfile",
                "Profile",
                "start launch profile space",
                \.tabs.startProfile,
                prompt: "The last one used"
            )
            .noted("A new window opens on this profile's first Space when it is not asked from another window.")
        ]
}
