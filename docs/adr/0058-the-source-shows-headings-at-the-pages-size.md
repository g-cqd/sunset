---
status: accepted
date: 2026-11-17
---

# 0058 — The Markdown source shows headings at the page's size by default, and code in colour only by its language

## Context

The owner (2026-11-17) asked for the source "to increase the font size of headings or just align a bit better the code being
written with what will be the rendered version", behind a toggle, defaults left to me; and found the code in the source
("a background and orange strings") hard to read: colour by the language named, else the standard colour.

## Decision

- `documents.largerHeadings`, on by default: a heading's text in the source takes the page's scale for its level (1.9,
  1.45, 1.15 em, then 1), bold, in the accent colour; its `#` stay at the body's size, dimmed. On by default because the
  request was for the source to look like its page; off, every line has one height, for those who want columns to line up.
  Settings > Documents > Editing.
- No setting for code: a fence whose language a scanner knows is coloured as the page colours it; any other code (another
  fence, an indented block, a code span) is in the text's colour; no code has a background (AemiMarkdown e8640c9).

## Consequences

- Lines of the source have different heights with the setting on. The source marks of a merge read the layout's line
  rectangles, so they follow; not yet seen on screen with a heading above a merged block.
- Proportional text, hidden markers and live inline preview are not done (roadmap 0034).
