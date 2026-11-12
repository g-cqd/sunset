# axdrive

Drives a test Sunset through the accessibility API without bringing it to the front (the owner, 2026-11-12: the screen is his, and nothing may
ever touch data that is not a test's).

**The guard.** Every command first reads the target's environment from the kernel (`KERN_PROCARGS2`) and goes on only for a process axdrive
launched: `AXDRIVE_TEST=1` and `SUNSET_CONFIG` inside `/tmp/axdrive/`. The owner's Sunset, any other app, a process whose environment cannot be
read: refused with exit 4, reading included. `launch` makes a fresh folder there (its own configuration, session, history, downloads), starts the
app with `SUNSET_BACKGROUND=1` and returns its pid once a window exists.

    read -r PID DIR < <(axdrive launch --session my-session.json --config '{"web":{}}')
    axdrive run "$PID" <<'STEPS'
    press Location --role button
    wait "wants to know your location"
    press OK --role button
    STEPS
    axdrive stop "$PID"

    swift build -c release --package-path Tools/axdrive
    Tools/axdrive/.build/release/axdrive help

- Search is ranked in tiers (1 exact name, 2 prefix, 3 word prefix, 4 substring, 5 letters in order), then by the field matched (title before
  help), an actionable role, enabled and visible. A clear winner is acted on; else the candidates are listed (exit 2) and `--pick N` or `--ask
  GOAL` decide; `--ask` asks the on-device model (Foundation Models, nothing leaves the Mac).
- Keys go to the process (`CGEvent.postToPid`), into its key window; a picture of a window works behind others.
- Menus are pressed without opening them. An item's enabled state is the one SwiftUI computed for the focused scene: with Sunset in the background
  some items (History > Reload Page) stay disabled; Sunset's menus fall back to the acting window (`TabRegistry.actingWindow`) where they can.

**Certainty.** A step is proven, not assumed: `--expect TEXT` / `--expect-gone TEXT` wait for the change it should cause (80 ms polls), and an
action whose target is still there after the timeout is done once more, never twice when it acted. A target is waited for until it exists and is
enabled (`--within`, 3 s). A match on letters in order alone is never acted on. Text goes in by keys first (the field editor, so SwiftUI hears
it), then by setting the value when the keys did not land. A failed step leaves `failed-step-N.png` and the tree beside the test's files.

Measured 2026-11-12: an 8-step flow (permission panel, menu, command bar typing, a page load) in about 1.3 s once launched, a launch in about
0.5-1 s; 40 of 40 runs passed after the last fix, with the owner's app in front throughout.
