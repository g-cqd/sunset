---
status: accepted
date: 2026-11-06
---

# 0033 — The app is SwiftUI and AppKit over two actors, with no Dispatch; the child gets a controlling terminal from `forkpty`

Owner notes n6 (fish does not work in Sunset), n7 (no GCD at all), n8 (the most modern APIs, checked in the Apple docs; SwiftUI and AppKit together where each is relevant) and the instruction to use Swift 6.4.2 and as much concurrency as possible.

## Decision

- **fish (n6) was a missing controlling terminal.** `posix_spawn` with `POSIX_SPAWN_SETSID` never gave the child one (measured on three variants of file actions: `tcgetpgrp` returned -1, `/dev/tty` could not be opened); a shell with job control refuses to run without it (fish: "No TTY for interactive shell (tcgetpgrp failed)"). `PTYProcess.spawn` now uses `forkpty`: everything the child needs is built before the fork and the child calls only system calls before `execve` (signals reset, descriptors closed, working directory set). A host test pins it (`tcgetpgrp` equals the child's group, `/dev/tty` opens); fish runs, with its prompt, colours and title, in the app.
- **No Dispatch anywhere** (n7; `BannedAPITests` fails the suite on any use in Sources, Tests or Benchmarks). Blocking waits on the pseudo-terminal (read, write) run on `DedicatedThread`s: a thread of its own that is a `TaskExecutor`, woken through a pipe; tasks prefer it with `Task(executorPreference:)` (`TaskExecutor`, macOS 15; checked in the Apple docs). `PTYProcess` is `Sendable` (its state is behind `Mutex`es), `read()` is a pulling `async` call (backpressure is the kernel's buffer), `send(_:)` queues in order and drops beyond 1 MiB (counted).
- **Two actors and values between them.** `TerminalSession` (SunsetHost) owns the program and the `Terminal`; it reads, parses, writes the terminal's replies, encodes keys *for the modes the program has set now*, and publishes `changed` / `closed` on an `AsyncStream` that keeps only the newest. `FrameRenderer` (SunsetRender) owns the CPU renderer and its surface. The window's `TerminalModel` (`@MainActor @Observable`) pulls: on each display-link tick, if a frame is wanted and none is being drawn, it asks the session for a snapshot (`takeSnapshot()` passes the dirty marks to the taker, so a frame always shows exactly what changed since the one before and nothing is lost or drawn twice), has the renderer draw it, and presents the bytes. The display link is paused when nothing is wanted.
- **SwiftUI where it is the right tool, AppKit where it is not.** SwiftUI: the `App`, the scenes (`WindowGroup`, `Settings`), the menu commands with a focused value, `@AppStorage` settings, the window title. AppKit: `TerminalNSView` (an `NSViewRepresentable`), because a terminal needs the raw key events, the text input system (`NSTextInputClient`, so dead keys and input methods compose) and a display link (`NSView.displayLink(target:selector:)`, macOS 14).
- **Option composes by default** (found in use: on a layout where `|`, `{`, `~`, `@` need Option, "Option as Meta" swallowed them); a setting turns Meta on.
- The grid is sized before the program starts, so a shell never draws its prompt into a 2-column window and is then resized (that left a mess of blank rows).
- Swift 6.4.2 (`.swift-version`, CI) and Swift 6 language mode with the strict settings for every target, executables included.

## Evidence

231 tests (host: 19, including the session actor's: output, replies and keys in order, resize, exit status, dirty marks passing to the snapshot taker, a flood of 60 000 lines, bounded input, stopping). The app was run: fish with prompt and colours, typed text, composed characters (`| ~ { } @ [ ] \` arrive), the title from OSC 2, a first frame with no blank rows after the sizing fix.

## Not established

- No measurement of the app yet: idle wakeups (the display link pauses; a 550 ms cursor blink task runs), frame latency, CPU per frame, memory. The path copies a frame's bytes twice (renderer to value, value to `CGImage`).
- Not done in the app: mouse, selection and copy, scrollback navigation, tabs and splits, find, the marked text of an input method is held but not drawn, window restoration, the Metal backend.
- Only an app run from a bare executable was tried (no bundle, no signing, no notarisation).
