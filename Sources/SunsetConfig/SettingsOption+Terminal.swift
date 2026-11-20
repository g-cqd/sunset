/// The options of Terminal.
extension SettingsOption {
    /// The font.
    static let text: [Self] =
        [
            Self(
                "font.family",
                "Font",
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
                "Font features",
                "font opentype zero ss01 stylistic",
                \.font.features,
                prompt: "zero, ss01, cv02=3"
            )
        ]

    /// The cursor: its shape, its colour, its blinking.
    static let cursor: [Self] =
        [
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
            )
            .grouped("Shape and color"),
            color("colors.cursor", "Cursor color", "caret color colour", \.colors.cursor, [229, 229, 229])
                .grouped("Shape and color"),
            toggle("cursor.blink", "Cursor blinks", "blink steady caret", \.cursorBlinks)
                .grouped("Blinking"),
            custom("cursor.blinkTimeout", "Stop blinking after", "blink caret idle seconds for ever", .blinkTimeout)
                .grouped("Blinking")
        ]

    /// Scrolling and the history.
    static let scrolling: [Self] =
        [
            number(
                "scroll.trackpad",
                "Trackpad scroll speed",
                "sensitivity speed touch finger scroll",
                \.scroll.trackpad,
                0.05 ... 20,
                step: 0.05,
                unit: "\u{D7}"
            ),
            number(
                "scroll.wheel",
                "Wheel scroll speed",
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
            custom("scrollback.lines", "Scrollback", "scrollback lines buffer memory history", .scrollback)
                .noted("The history length applies to windows opened after the change.")
        ]

    /// The shell and the programs.
    static let shell: [Self] =
        [
            text(
                "terminal.directory",
                "Starting directory",
                "directory folder home cd path",
                \.terminal.directory,
                prompt: "~"
            )
            .folder(),
            toggle(
                "terminal.shellIntegration",
                "Mark prompts in zsh",
                "integration osc 133 zsh",
                \.terminal.shellIntegration
            )
            .noted("For Previous Prompt and Next Prompt, in new zsh tabs. fish does it itself."),
            toggle(
                "keyboard.optionAsMeta",
                "Option sends Escape",
                "meta alt option emacs",
                \.keyboard.optionAsMeta,
                label: "Option sends Escape"
            )
            .noted("As Meta does, for the shell's and editors' keys.")
        ]

    /// How the terminal is drawn.
    static let rendering: [Self] =
        [
            choice(
                "renderer",
                "Renderer",
                "gpu cpu metal auto graphics",
                \.renderer,
                [(.auto, "Automatic"), (.gpu, "GPU"), (.cpu, "CPU")]
            )
            .noted(
                "GPU draws with Metal, CPU on the processor; Automatic picks the GPU when the machine has one. Both draw the same "
                    + "pixels."
            )
        ]
}
