---
status: accepted
date: 2026-11-17
---

# 0067 — What a page has Sunset fetch, or ask the person, is bounded

## Context

The review of 2026-11-17 of the work merged that day (roadmaps 0035–0038) found three ways a page reached past its own
sandbox through Sunset (white paper §9):

- a site's icon is fetched from the address the page's `<link rel="icon">` names, whatever its scheme: a `file:` address
  had Sunset read a file of the Mac, and keep it as the site's icon in the state database (roadmap 0035 H);
- a site's icon and a notification's picture were read whole before their size was looked at;
- `Notification.requestPermission()` asked the person each time it was called, from any script, with or without a click;
  each call waited in a loop of its own while another question was up.

## Decision

- What Sunset fetches for a page goes through `WebFetch`: only `http`, `https` and `data:` addresses, as the browser the
  site is shown, without cookies, and never more than a limit (1 MiB for an icon or a notification's picture): a response
  that says it is longer is not read, and one that goes past the limit is cut off and refused.
- A page's notification question is shown only from what the person did (`navigator.userActivation.isActive`, as Safari
  requires a gesture), and one at a time per page: a request without a gesture, or made while the question is up, is
  answered by the site's answer as it stands ("default" when it has none).
- A notification's picture the notification centre refuses is removed from the temporary folder.

## Consequences

- A site that asks for notifications at load, without a click, is never asked about; the person can still allow it in
  the site's settings. The same holds in Safari.
- A site's icon larger than 1 MiB is not shown.
- Not done: the same rule for the other questions a page can raise through WebKit (camera, microphone, location), which
  WebKit gates itself; a link of a document that opens another app (`.system`) is still opened without a question.
