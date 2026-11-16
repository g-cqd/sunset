---
status: accepted
date: 2026-11-15
---

# 0037 — Every pane is drawn on the terminal's background

## What asked for it

The owner, 2026-11-15, with the build in hand: "background for documents and all other panes should use the same background we
use for terminals screens". A document was on AppKit's text background, the settings and an empty web pane on its window
background, and each was clear over a window that is not opaque: three surfaces in one window, none of them the terminal's.

## Decision

- **One value, `PaneBackdrop` (`SunsetShell`)**: the theme's `colors.background` (the terminal's black with none) and how
  opaque the terminal is seen. It is in `PaneViewContext`, so a pane's content needs nothing of the configuration.
- **Every `PaneContent` that is not a terminal draws on it** with `paneBackdrop(_:)`: a document, the settings, the
  placeholder of an unknown kind, a web pane with no page or a page that failed. A terminal goes on drawing its own.
- **A web page keeps its own colour.** What a site draws is the site's; only what Sunset draws around or instead of it changes.
- **The colour scheme inside such a pane follows the background, not the window**: dark text on a light theme's background,
  light on a dark one, by the background's luminance (Rec. 709, below 128 is dark), as the window's light tint is decided.
- **As opaque as a terminal is seen, not as `terminal.opacity` says.** A terminal has its background twice, one over the
  other (its view's layer and its frame's pixels), so it lets `(1 - a)²` through. The backdrop's alpha is `1 - (1 - a)²`.
  Measured: composed once, a document was 35 where the terminal next to it was 27, over the window's 44.

## Not decided here

Whether a terminal should have its background once (which would make `terminal.opacity` mean what it says, and change how every
translucent window looks) is left as it is.
