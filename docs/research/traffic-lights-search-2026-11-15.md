# How Search lays out the traffic lights, and what Sunset did

Asked by the owner on 2026-11-15: "investigate how the office commun 'search' project lays out the traffic lights, because it
seems our implementation is shit as hell"; and, of ours, "they start in the wrong place".

Search is a browser for the Mac by Office Commun (`/Applications/Search.app`, `com.officecommun.search` 1.0.12), open
source under the MIT licence at `github.com/driceroland/Search`. Read at its commit `0f6d9e0` (2026-11-15):
`Sources/Search/Lights.swift` (154 lines) and where `App.swift` calls it. It was read, not copied: none of its code is in
Sunset. What it says of itself is its own; what is measured below is ours, on this Mac (macOS 27.0.1).

## What Search does

1. **The buttons stay AppKit's, in its title bar.** They are never taken out of it. The title bar's container is made as
   tall as Search's strip, so that the buttons can sit lower in it, and each button's origin is set within its own bar.
2. **It assumes AppKit will move them back, and watches for that.** In its words: "AppKit lays its title bar out again
   whenever it sees fit (a resize, full screen, the window becoming key), so every time it does, the buttons are put
   back." It listens to six window notifications (resized, end of live resize, became key, resigned key, left full screen,
   changed screen) and, "the surest sign", to the frame of the container, of the bar and of each button changing.
3. **Putting back is cheap and guarded.** A flag stops it from answering its own moves; `refreshIfMoved` does the same
   arithmetic without changing anything, for a page whose title changes every second.
4. **The spacing is read once.** Read at every pass, it was once caught while AppKit was half way through moving the
   buttons, and the three closed up; its comment dates the reproduction.
5. **Full screen is left to macOS** (the title bar is then in a window of its own).
6. **No toolbar.** An empty toolbar is the public way to move the buttons, and it used one; on macOS 26 a toolbar rounds the
   window's corners almost twice as much (its measure: 31.5 pt against 17.5), so it places them by hand instead.
7. It also raises the title bar's container above the content view's layer (a white patch otherwise, it says), and draws
   resting circles of its own when the app is behind.

## What Sunset did

`ChromeView.placeButtons` took the three buttons **out of the title bar** and put them in the window's frame view, so that
they could be anywhere in the window, then set their frames. It placed them again on the same six window notifications and
whenever SwiftUI laid the chrome's view out. Nothing watched the buttons themselves.

## What was measured

Harness: `Scripts/lights-probe/run.sh` (a test copy of the app; a picture of its window three seconds after it starts; where
something is drawn in its top 35 pt), and a dump from inside the app of the buttons' parents and frames, added for the
investigation and removed.

| Case | Sunset before (2708d20) | Sunset after |
| --- | --- | --- |
| Sidebar on the right, a new window | Buttons at **(9, 9), (32, 9), (55, 9): the top left**, over the terminal | (748, 12), (771, 12), (794, 12) in an 820 pt window: in the sidebar, mirrored |
| Sidebar on the left | (9, 9): AppKit's place, not ours | (12, 12), (35, 12), (58, 12) |
| No sidebar | (9.5, 9) | (8, 8), where `window.trafficLights.*` says |
| The sidebar hides | none drawn | none drawn |
| The system's title bar | (9, 9), AppKit's | the same |

The mechanism, from the dump: before the window shows, the buttons are in the frame view where Sunset put them. Within
100 ms of the window showing, **AppKit has put the same three buttons back in its title bar view at (9, 9)**, and no
notification Sunset listened to follows. They stay there until something else makes Sunset place them (a resize, the window
becoming key). Seen every time with a new window, and every time while the screen is being recorded; a window restored at
its saved size often escaped it, which is why it had not been seen in the pictures taken through the day.

A small AppKit program outside Sunset shows the same of both ways: after a resize AppKit sets the buttons back to (9, 9)
**in whatever view they are in** (taken out into the frame view, that is the bottom left of the window). Either way has to
put them back; only Search's notices every time.

Pictures of the first frames of a window, recorded with nothing of the owner's screen in them:
`docs/research/lights/start-before.png` (the buttons at the right in the first frame, at the top left from the second) and
`start-after.png` (at the right in every frame).

## What Sunset does now

Search's principle, in Sunset's own code (`SunsetShell/WindowLights.swift`, ADR-0036): the buttons stay in AppKit's title
bar; they, their bar and its container are watched, and each time one moves they are put back; the spacing is read once;
full screen is left alone.

Not taken from Search: its resting circles and its raised layer (Sunset's buttons were seen drawn above its content without
it). Not checked in Sunset: the pointer over the buttons (their symbols), which cannot be made in the background.
