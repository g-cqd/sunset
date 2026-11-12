# axdrive

Drives an app through the accessibility API without bringing it to the front (the owner, 2026-11-12: the screen is his). Sunset is started with
`SUNSET_BACKGROUND=1` so it does not activate itself.

    swift build -c release --package-path Tools/axdrive
    Tools/axdrive/.build/release/axdrive help

- Search is ranked in tiers (1 exact name, 2 prefix, 3 word prefix, 4 substring, 5 letters in order), then by the field matched (title before
  help), an actionable role, enabled and visible. A clear winner is acted on; else the candidates are listed (exit 2) and `--pick N` or `--ask
  GOAL` decide; `--ask` asks the on-device model (Foundation Models, nothing leaves the Mac).
- Keys go to the process (`CGEvent.postToPid`), into its key window; a picture of a window works behind others.
- Menus are pressed without opening them. An item's enabled state is the one SwiftUI computed for the focused scene: with Sunset in the background
  some items (History > Reload Page) stay disabled; Sunset's menus fall back to the acting window (`TabRegistry.actingWindow`) where they can.
