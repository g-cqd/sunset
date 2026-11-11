---
status: accepted
date: 2026-11-06
---

# 0010 — Every untrusted action has a policy

Owner note n5 asks for the whole OSC set. A terminal reads bytes written by whatever runs in it (a `cat` of a downloaded file, a remote host, a build log), so each sequence that reaches outside the screen needs a rule before it is implemented, and a test written red first. Defaults deny or are bounded; a setting can loosen them; nothing the program sends can raise its own privileges. Accepted on the owner's request to implement the OSC scopes; the owner may change any default below.

## The rules

| Sequence | Default | Bounds and sanitising |
|---|---|---|
| **OSC 52 write** (`52;c;base64`) | allowed | payload at most 1 MiB of base64 (the OSC buffer is raised to that for code 52 only; any other code stays 4096 bytes); invalid base64 or invalid UTF-8 is dropped whole, not repaired; one pasteboard (macOS has no primary selection: `c`, `p`, `s` all mean it); empty data clears nothing (a program cannot wipe the clipboard) |
| **OSC 52 read** (`52;c;?`) | **denied, no reply** (not even an empty one: a reply is visible to the program and tells it the answer) | a setting to ask is future work (needs UI) |
| **OSC 22** (pointer shape: `name`, `=name`, `>push`, `<pop`, `?query`) | allowed | CSS names only (30 known; an unknown one changes nothing); a stack of 16 per screen, the oldest dropped; a query is answered with `1`/`0` per name within the 64-byte reply bound, else not at all; the host shows the nearest system pointer |
| **OSC 8** hyperlinks | stored on cells, opened only by an explicit user gesture (Command-click), never on hover or output | URI at most 2083 bytes, no control characters, scheme allow-list `http https mailto file ssh` (others are kept as text but never opened); `file:` only when the host is empty or the local host name; at most 64 K distinct links per screen (older ones lose their link) |
| **OSC 7** working directory | recorded, used only to start a new window or tab in that directory | `file://host/path` parsed and percent-decoded, at most 4096 bytes, control characters rejected, must be an absolute path; **never reported back** (a query would leak it) |
| **OSC 133** prompt marks (A B C D, exit status) | recorded as marks on lines | at most 4096 marks kept per screen (oldest dropped); the exit status is a number 0-255 or dropped; options (`aid=`, `k=`, etc.) are ignored, never executed |
| **Notifications** (OSC 9, OSC 777;notify, OSC 99) | delivered by the host only while the window is not focused, at most one a second | title at most 256 and body at most 1024 bytes, control characters removed; no icons, sounds, buttons, URLs or file reads are taken from the sequence; OSC 99 queries get no reply |
| **OSC 9;4** progress (ConEmu) | recorded as a state and a percentage 0-100 | other values dropped |
| **Titles** (OSC 0 1 2) | as ADR-0027 | sanitised, never reported back |
| **Colours** (OSC 4 10-12 104 110-112) | as ADR-0027 | |
| **OSC 1337** (iTerm2) | `SetMark` (= a prompt mark) and `CurrentDir` only | everything else (file transfer, inline images, user variables, `RequestUpload`) is ignored until graphics have their own policy (file reads, shared memory, quotas) |
| **OSC 66** text sizing | not yet (needs the renderer) | |
| Paste | bracketed when the program asked; the end marker is stripped (done) | |
| Query replies | only safe ones (ADR-0026) | |
| Remote control | peer-credential check on the socket, ADR-0022 | |

## How the pieces are cut

The core never touches the system. The screen turns these sequences into **events** (`HostEvent`: clipboard write, notification, working directory, prompt mark, progress) in a bounded queue the host takes after each batch, like replies; the host applies the policy that needs the system (the pasteboard, the notification centre, opening a link). The queue holds at most 64 events and drops the oldest, so output that sends a million notifications costs a bounded amount. Hyperlinks and prompt marks are state on the screen, not events.

## Not established

The limits are my choices, not measured against any program's real use (OSC 52 of 1 MiB is what kitty documents as a typical maximum). What kitty, ghostty and iTerm2 do with malformed forms is not compared yet. Whether write-allowed is the right default for a first release is the owner's call (kitty and ghostty allow write and ask for read; xterm denies both by default).
