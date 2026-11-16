---
status: accepted
date: 2026-11-16
---

# 0042 — A debug build is another app than the installed one

## What asked for it

Every build had the identifier `studio.aemi.sunset`, so to the Mac a test copy *was* the owner's app. On 2026-11-16 that
cost four things: a test copy's saved state took the window away from every Sunset (ADR-0039); test copies replaced the
window frame his app remembers, twice; with the document types of M-f, which of the two the Finder starts for a file was
the system's choice; and `open -a` on a debug build with no test copy running started a Sunset on his real session, which
it wrote. The owner, asked: **debug builds become `studio.aemi.sunset.dev`**.

## Decision

1. **The Debug configuration has the identifier `studio.aemi.sunset.dev` and the display name "Sunset Dev"** (`project.yml`).
   Its defaults, saved state, privacy permissions and Open With entry are its own. The process and the application menu
   are still called Sunset; the Quit item is "Quit Sunset Dev" (`axdrive quit PID` presses it whatever the name).
2. **Started with nothing named, a development build keeps its own folder and its own keys**:
   `~/Library/Application Support/Sunset Dev`, and the Keychain items `studio.aemi.sunset.dev.storage-key` and
   `…dev.command-seal` (`StoragePlaces`, told the bundle identifier). It never reads or writes the person's session and
   never asks for his keys.
3. **A named setup never touches the Keychain at all**: the key that seals kept terminals' commands is now a file beside
   its other files (`command-seal.key`), as the store's key already was. Before, a test copy read the person's.
4. **The configuration file is still shared** (`~/.config/sunset/config.json`) by a development build started by hand: it
   is the person's preferences, read at start and written only from Settings. Test copies name their own.
5. **A release build is the installed app**, and a test of it shares the defaults: `Scripts/smoke-app.sh` starts it once
   as a test copy, and puts back the window frame the person's app remembers.

## Consequences

- macOS asks again, once, for the permissions a debug build needs (folders, the camera for a page): they are another app's.
- "Sunset Dev" is listed beside "Sunset" in Open With while a debug build exists on the disk.
- A measurement made with a release build under axdrive still shares the owner's defaults; only the frame is put back.
