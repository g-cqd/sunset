---
status: accepted
date: 2026-11-19
---

# What Sunset puts in a page reads as WebKit's own

## Context

The web tester's inventory (diary 2026-11-19-04) compared every interface and member a page sees in Sunset against a
driven Safari. Sunset was told apart by what it added: two functions on `window` for a share's frames (their token
enumerable, so any script could list and call them), a `Notification` shaped unlike WebKit's (`__fire`, `maxActions`,
attributes as own fields, the standard's TypeErrors WebKit does not throw), source text that was not `[native code]`, and
Private Click Measurement attributes on links, which Safari has off. A window event carried the person's notification
clicks: a page could fire it and make its own notifications look clicked.

## Decision

- Nothing of Sunset's on a page's window or its objects. What Sunset gives a page (a share's frames, a notification's
  clicks) the page's script pulls through Sunset's message handler; Sunset answers only the frame WebKit says asked
  (a share: the origin that asked for it; notifications: the main frame).
- What Sunset replaces has WebKit's shape, read in a bare WKWebView: the prototype's accessors and operations, their
  names, lengths, enumerability, brand checks and error words; `Function.prototype.toString` says `[native code]` for
  them (`PageNative`, chained with the agent script's).
- WebKit features Safari has off are off (`WebFeature`; Private Click Measurement first).
- `PageFootprintTests` holds the shape; the inventory against a driven Safari is the measure.

## Consequences

- An event fired by a script is not trusted: a page can still tell a notification click is Sunset's by `isTrusted`.
- A page reading `Notification.requireInteraction`, `renotify`, `timestamp` or `actions` finds none, as in Safari.
- What Safari has that WebKit's views have not (Payment Request, Apple Pay, Push: task t98) still tells them apart.
