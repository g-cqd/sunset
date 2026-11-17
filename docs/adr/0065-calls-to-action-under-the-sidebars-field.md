---
status: accepted
date: 2026-11-17
---

# 0065 — Calls to action under the sidebar's field: the pages' questions, and what macOS must allow Sunset

The owner, 2026-11-17 (roadmap 0035 I): "calls to action for allowing and authorizing stuff below the address bar". His
answer: the pages' permission questions, and what macOS must allow Sunset itself, with a way to System Settings.

## Decision

1. **Under the sidebar's field**, docked, a card for each question of a page of the shown tab (what the site wants, Don't
   Allow, Once, Allow): it is no longer drawn over the page while the sidebar is docked (`permissionsInSidebar`); floating
   or without the sidebar, the panel over the page stays. The rows move down by the cards' height.
2. **What macOS must allow Sunset** (`SystemAsk`): notifications, the camera, the microphone, the location, each shown
   only **while a site may use it** (allowed, or allowed by default) and macOS has not allowed it: notifications not yet
   asked get "Allow…" (macOS asks), anything refused gets "Open System Settings" at its pane. The camera, the microphone
   and the location not yet asked are left to macOS, which asks when a page first needs them. Looked at when Sunset starts
   and each time it comes to the front (`SystemAuthorizations`).

## Seen

A local page calling `Notification.requestPermission()`: the card under the field, none over the page; Don't Allow: the
page's promise gave "denied".

## Not done

- The system cards were not seen (they need a site allowed and macOS refusing, on the owner's Mac).
- A question of a page in a tab that is not shown waits, unseen, as before.
