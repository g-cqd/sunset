---
status: accepted
date: 2026-11-22
---

# Filling and saving run in Sunset's own world, on the person's act

## Context

A page is untrusted (white paper §9); a fill engine is what phishing and hidden forms attack. `SignInWatch` (ADR-0081)
already runs in Sunset's own content world. ADR-0089 keeps Sunset's footprint out of the page's world.

## Decision

- **Where:** the fill and save scripts run in Sunset's own `WKContentWorld`, in every frame; a frame tells its fields
  only when it and every frame above it are of the page's origin (checked in the frame, by the documents' origins, and
  again by the app against WebKit's `WKFrameInfo`, never what the page says), so where it is in the page is known. A
  frame of another origin, or a sandboxed one, is offered nothing. A fill runs in the frame whose field took the keyboard.
- **Suggestions** are drawn by Sunset, outside the page, as macOS's own AutoFill: a small popover under the field that
  took the keyboard, only when the vault is unlocked and has logins for the page's site; it never takes the keyboard; the
  row under the pointer is highlighted as a menu's; nothing is filled until one is clicked (the owner, 2026-11-22: as
  distraction-free and native as can be). The page cannot read them, cover them, or click them.
- **Filling:**
  - only on the person's act (choosing the suggestion, a key);
  - on load only when the person allows it (`passwords.autoFill`, off unless set): an https page, not private, on
    screen; the site's one login, saved for the page's very origin (scheme, host and port); the first sign-in form shown
    within ten seconds of load (not a sign-up form's), and only if no password is typed in it, its username is empty or
    the same, and it is sent to the page's own origin; in the main frame or a frame of the page's origin; no Touch ID,
    as a click on a login asks none;
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
- **Contact and address fields** (told by their HTML autofill token, else their type, else their name; a sign-in form's
  email stays its username) are offered the vault's identities, which are not tied to a site, and filled without Touch
  ID, as Safari fills contacts: names, email, phone and the address in parts (street, city, postal code, region,
  country), never a password's, a code's or a card's field. An identity whose address is one piece is not filled from it.

- **Only the person's acts** count: a focus, a submit, a key or a click the page makes up (untrusted) shows nothing and
  offers nothing.
- **A fill is for one origin**: the one its suggestion was made for, checked in the page in the same turn as the fill.
- **A secret copied** leaves the clipboard after 90 seconds, unless something else was copied since.

## Consequences

Every rule above is a policy with a test (a page with a hidden field, a cross-origin frame, a look-alike host).
