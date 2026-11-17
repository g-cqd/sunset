---
status: done
blocked-by:
date: 2026-11-17
---

# 0034 — The Markdown source, closer to its page: larger headings behind a setting, code coloured by its language only

Asked by the owner on 2026-11-17. Task t295. Done: A (AemiMarkdown e8640c9), B (AemiMarkdown 847a761, ADR-0058), C (on
screen, diary 2026-11-17-02).

## What he asked

"enable a better rendering behind a toggle for the rendering in sunset to increase the font size of headings or just align a
bit better the code being written with what will be the rendered version", deciding the defaults myself; and "the rendering
of the codeblocks in markdown with a background and orange strings in editing tab is not really nice to read and i'd prefer
that you highlight syntax depending on the language mentioned but else you keep it plain white or standard color".

## What the source view did before step A

One font size everywhere ("a heading is bold and tinted, not larger, so lines keep one height"); a heading in the accent
colour; every byte of code orange (`systemOrange`) on a grey background; the fence's language teal; markers tertiary.

## Steps

- **A — code as the page shows it (no setting). Done**, AemiMarkdown `SourceRun`, diary 2026-11-17-02. A fenced block whose language a scanner knows (the scanners the page
  already uses for its code, `AemiLexers`) is coloured as on the page; any other code, and a code span, is the label colour
  with no background. The fence and the language stay dimmed as markers. Test: a `swift` fence gets the page's colours, an
  unknown language and a code span get `labelColor` and no `.backgroundColor`.
- **B — `documents.largerHeadings`, on by default. Done** (a toggle rather than the two-valued `sourceLook` first written
  here; ADR-0058). On: a heading's text takes the page's heading scale (the native view's `Spacing.scale(.heading(n))`, 1.0
  for body) and weight, the `#` markers at the body's size, tertiary; a quote's text secondary; emphasis and strong as now. `plain`: today's single size. The default is `page`
  because the owner asked for the source to look like what it becomes; the setting exists for those who want columns to
  line up. Lines are then of different heights: the editor's measured scroll and the source marks (`SourceMarksFinder`)
  must use the layout's line rectangles, not a fixed line height — to probe first, red, with a document of headings.
- **C — on screen.** `/tmp/am/check.md` and a long README in both looks, captured, in the diary.

## Not done

The source marks of a merge under a larger heading are not seen on screen. A long README in both looks is not captured
(C used three short fixtures). Proportional body text in the source (it stays the editor's font), hiding markers, and live preview inline
(Typora-style) are not proposed.
