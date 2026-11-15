/// The options of the Font, Colors, Scrolling, Terminal, Keyboard and Configuration file panes.
extension SettingsOption {
    static let font = pane(
        "font",
        [
            Self(
                "font.family",
                "Family",
                "font typeface name menlo jetbrains",
                .optionalText(SettingsValue(\.font.family), prompt: "Menlo, SF Mono, JetBrains Mono\u{2026}")
            ),
            number(
                "font.size",
                "Size",
                "font points zoom bigger smaller",
                \.font.size,
                4 ... 200,
                step: 0.5,
                digits: 1
            ),
            toggle("font.ligatures", "Ligatures", "font calt liga arrows", \.font.ligatures),
            text(
                "font.features",
                "Features",
                "font opentype zero ss01 stylistic",
                \.font.features,
                prompt: "zero, ss01, cv02=3"
            )
        ]
    )

    static let colors = pane(
        "colors",
        [
            color("colors.foreground", "Foreground", "text color colour theme", \.colors.foreground, [229, 229, 229]),
            color("colors.background", "Background", "color colour theme", \.colors.background, [0, 0, 0]),
            color("colors.cursor", "Cursor", "caret color colour", \.colors.cursor, [229, 229, 229]),
            custom("colors.ansi", "ANSI colors", "palette 16 red green blue terminal colors kitty", .ansiPalette)
        ]
    )

    static let scrolling = pane(
        "scrolling",
        [
            number(
                "scroll.trackpad",
                "Trackpad (lines per line of travel)",
                "sensitivity speed touch finger scroll",
                \.scroll.trackpad,
                0.05 ... 20,
                step: 0.05,
                unit: "\u{D7}"
            ),
            number(
                "scroll.wheel",
                "Wheel (lines per notch)",
                "sensitivity speed mouse notch scroll",
                \.scroll.wheel,
                0.05 ... 50,
                step: 0.05,
                unit: "\u{D7}"
            ),
            number(
                "scroll.inertia",
                "Wheel inertia",
                "glide momentum smooth mouse deceleration scroll",
                \.scroll.inertia,
                0 ... 2,
                step: 0.05,
                unit: "s"
            )
            .noted("How long a wheel notch glides (0: none). A trackpad uses the system's own momentum."),
            custom("scrollback.lines", "History", "scrollback lines buffer memory", .scrollback)
                .noted("The history length applies to windows opened after the change.")
        ]
    )

    static let terminal = pane(
        "terminal",
        [
            number(
                "terminal.opacity",
                "Background opacity",
                "transparent alpha see through screen translucent",
                \.terminal.opacity,
                0 ... 1,
                step: 0.05,
                unit: ""
            )
            .noted(
                "How opaque the terminal screen's own background is. It only shows when the window background is not Opaque "
                    + "(Window / Appearance); the sidebar follows the window's settings."
            ),
            choice(
                "cursor.shape",
                "Cursor shape",
                "block underline bar caret beam",
                \.cursorShape,
                [(.block, "Block"), (.underline, "Underline"), (.bar, "Bar")]
            )
            .noted(
                "What programs get unless they choose their own cursor (an editor often does); they get it back when they "
                    + "ask for the default."
            ),
            toggle("cursor.blink", "Cursor blinks", "blink steady caret", \.cursorBlinks),
            custom("cursor.blinkTimeout", "Stop blinking after", "blink caret idle seconds for ever", .blinkTimeout),
            choice(
                "renderer",
                "Renderer",
                "gpu cpu metal auto graphics",
                \.renderer,
                [(.auto, "auto"), (.gpu, "gpu"), (.cpu, "cpu")]
            )
            .noted(
                "GPU draws with Metal, CPU on the processor; auto picks the GPU when the machine has one. Both draw the same "
                    + "pixels."
            ),
            text(
                "terminal.directory",
                "New terminals start in",
                "directory folder home cd path",
                \.terminal.directory,
                prompt: "~"
            ),
            toggle(
                "terminal.shellIntegration",
                "Shell marks its prompts",
                "integration osc 133 zsh",
                \.terminal.shellIntegration
            )
            .noted("For Previous Prompt and Next Prompt, in new zsh tabs. fish does it itself."),
            toggle(
                "terminal.clipboardWrite",
                "Programs may copy",
                "clipboard osc 52 pasteboard ssh",
                \.terminal.clipboardWrite,
                label: "Programs may copy to the clipboard"
            )
            .noted("What a program asks to copy (OSC 52), over ssh too. No program can read the clipboard.")
        ]
    )

    static let keyboard = pane(
        "keyboard",
        [
            toggle(
                "keyboard.optionAsMeta",
                "Option sends Escape",
                "meta alt option emacs",
                \.keyboard.optionAsMeta,
                label: "Option sends Escape (Meta)"
            )
        ]
    )

    static let file = pane(
        "file",
        [
            custom("file.location", "Location", "path json config reveal editor errors problems", .fileLocation)
                .setting([])
        ]
    )
}
