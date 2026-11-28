---
status: accepted
date: 2026-11-28
---

# 0132 — HTML, XHTML and SVG files open drawn, their source a toggle away

## Context

An `index.html` opened in Sunset showed its source as plain text. The owner asked that a file Sunset can draw open drawn,
with its source to edit and the page following the edits (2026-11-28). A local HTML file runs scripts and names other
files and addresses; opening one must not give it more than a browser opening it from disk would, and less where Sunset
can.

## Decision

- **A page is a document kind** (`DocumentKind.page`: `.html`, `.htm`, `.xhtml`, `.svg`). It opens rendered (an empty one
  as source, as any document); Show Source and Show Beside work as for Markdown and Mermaid. Its text, edits, undo,
  saving and merges are the document's, as for any file.
- **WebKit draws it, outside the document module**: `SunsetMarkdown` has no WebKit; the app gives
  `DocumentContent.pageView`, which draws `LocalPageView` (`SunsetWeb`).
- **What it draws is the editor's text**, a quarter of a second after the last keystroke, saved or not, where the page was
  scrolled to. The file is loaded first (`loadFileURL`, with read access to its folder only), so that its relative styles,
  scripts and pictures load; the text is then drawn over it with the file as its base.
- **Its folder is watched**: a file saved there (a style, a script) draws the page again, read anew (`reloadFromOrigin`).
  The file itself comes back through the document, which already follows its file.
- **It is kept apart**: website data that is not kept (`nonPersistent`), no profile's cookies or logins, no extensions, no
  password filling. It reaches only files, `data:`, `blob:` and `about:` unless `documents.pagesReachNetwork` is on (off by
  default): a content rule list blocks the rest.
- **Its links are Sunset's**: a click on a link is caught in a script world of Sunset's own (the page's scripts cannot post
  to it) and opened as a document's link is (`documents.linksOpen`, the keys held): another page or file as a document, an
  address in a tab. Any other navigation of the page is handed over the same way; a jump within it stays.

## Consequences

- A link that opens a window (`target="_blank"`) or a script that does is not followed yet.
- In-place writes to a file of the folder (not saved as a new file) may not be seen by the folder's watch.
