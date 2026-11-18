---
status: accepted
date: 2026-11-18
---

# 0075 — A terminal notifies when its pane is not seen, not only when Sunset is in the background

Supersedes the notifications row of ADR-0010 on one point: when.

## Context

ADR-0010 delivers a program's notification (OSC 9, 777, 99) "only while the window is not focused". It was built as
"only while Sunset is not the app in front" (`NSApp.isActive`), so a program in a tab nobody looks at, in a window
behind, or in another Space of a Sunset in front, never notified. The owner, 2026-11-18: "No notifications at all are
requested even though some tabs might be emitting some" (roadmap 0045 B). The system's log on his Mac shows Slack's
page notifications posted and presented by Sunset that day, and nothing from a terminal.

## Decision

A notification is held back only when the person sees the pane that asked: Sunset is in front, the pane's window is the
key window and on screen, and the pane is shown in it (`NotificationGate.seen`). Otherwise it is posted, at most one a
second as before. The rest of ADR-0010's row (sizes, what is taken from the sequence) is unchanged.

## Consequences

More notifications reach the person; each still names the tab and its Space and a click brings that tab forward
(roadmap 0021 S-e). A program in a split pane beside the one being typed in is seen, and does not notify.
