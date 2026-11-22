---
status: accepted
date: 2026-11-22
---

# Filling and saving run in Sunset's own world, on the person's act

## Context

A page is untrusted (white paper §9); a fill engine is what phishing and hidden forms attack. `SignInWatch` (ADR-0081)
already runs in Sunset's own content world. ADR-0089 keeps Sunset's footprint out of the page's world.

## Decision

- **Where:** the fill and save scripts run in Sunset's own `WKContentWorld`, in every frame. A frame's origin is WebKit's
  `WKFrameInfo`, never what the page says.
- **Suggestions** are drawn by Sunset, outside the page, as macOS's own AutoFill: a small popover under the field that
  took the keyboard, only when the vault is unlocked and has logins for the page's site; it never takes the keyboard; the
  row under the pointer is highlighted as a menu's; nothing is filled until one is clicked (the owner, 2026-11-22: as
  distraction-free and native as can be). The page cannot read them, cover them, or click them.
- **Filling:**
  - only on the person's act (choosing the suggestion, a key);
  - automatic fill on load only when the person allows it, and only for an exact match;
  - never into a hidden field;
  - never into a frame of another origin than the entry's site;
  - on http only after a warning.
- **Matching:**
  - by registrable domain (the bundled Public Suffix List, ADR-0108); an IP address, `localhost` or a single label is a
    site of its own;
  - each URL of an entry may say host, exact, prefix, regex or never.
- **Saving** is offered after a form is sent, in the same kind of popover, pointing at the password field sent: Save (or
  Update), Never for This Site, Not Now; clicked away, it is Not Now. Once a page; only what the vault does not have;
  never silent; never in a private window; not while the vault is locked.
- Both popovers are drawn on the window's own background, not translucent: legible in front or not.
- **Security codes** (cards) are never filled without a reveal.

## Consequences

Every rule above is a policy with a test (a page with a hidden field, a cross-origin frame, a look-alike host).
