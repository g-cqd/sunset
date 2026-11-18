---
status: accepted
date: 2026-11-18
---

# 0077 — Asking about notifications without a click, and a service worker's notifications, are settings

Changes ADR-0067 on one bound (a page's notification question needs a gesture) and roadmap 0042's "not to be done" on one
point (a service worker's notifications), at the owner's word, 2026-11-18: "this could be a setting", for each.

## Decision

1. `web.notificationsWithoutClick`, off: as Safari and ADR-0067, a request without a gesture asks nobody. On: as Chrome, it
   asks the person, still one question at a time, still from the page itself and not a frame.
2. `web.workerNotifications`, on: a page's `registration.showNotification(…)` is posted as its own notifications are, under
   the same answer and the same one-a-second bound, while the page is open. Off: refused. What a worker shows by itself from a
   push, with no page, still reaches nothing (an app's web view has no push service).

## Consequences

A site can ask as soon as it opens when the first is on: the person chose it. The worker's `notificationclick` is not
fired; a click on such a notification shows its tab, as any of the page's.
