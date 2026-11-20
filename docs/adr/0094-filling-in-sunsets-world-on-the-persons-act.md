---
status: accepted
date: 2026-11-20
---

# Filling and saving run in Sunset's own world, on the person's act

## Context

A page is untrusted (white paper §9); a fill engine is what phishing and hidden forms attack. `SignInWatch` (ADR-0081)
already runs in Sunset's own content world. ADR-0089 keeps Sunset's footprint out of the page's world.

## Decision (proposed)

- **Where:** the fill and save scripts run in Sunset's own `WKContentWorld`, in every frame. A frame's origin is WebKit's
  `WKFrameInfo`, never what the page says.
- **Suggestions** are drawn by Sunset, outside the page. The page cannot read them, cover them, or click them.
- **Filling:**
  - only on the person's act (choosing the suggestion, a key);
  - automatic fill on load only when the person allows it, and only for an exact match;
  - never into a hidden field;
  - never into a frame of another origin than the entry's site;
  - on http only after a warning.
- **Matching:**
  - by registrable domain, which needs the Public Suffix List: the owner's call (§8), by host until then;
  - each URL of an entry may say host, exact, prefix, regex or never.
- **Saving** is offered after a form is sent, in a bar outside the page, once a page; never silent; never in a private
  window.
- **Security codes** (cards) are never filled without a reveal.

## Consequences

Every rule above is a policy with a test (a page with a hidden field, a cross-origin frame, a look-alike host).
