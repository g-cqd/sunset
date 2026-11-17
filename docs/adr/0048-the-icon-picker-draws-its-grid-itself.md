---
status: accepted
date: 2026-11-17
---

# 0048 — The icon picker draws its grid itself, from pictures, and offers emoji

## What asked for it

The owner, 2026-11-17: "the symbol selection should be refined because it's not really performant right now at loading
all symbols (also its use for the tabs)"; then: "the rendering and scrolling through the list should also be
instantaneous, and it should allow for emojis as well as symbols".

Measured before anything was changed (release, this machine, 6,751 symbols, `SymbolPickerBenchTests`):

| What | Cost, p50 |
| --- | --- |
| The catalog read at each opening of the picker (off the main actor, a spinner meanwhile) | 21 ms |
| A search, at each key typed and again at every redraw (main actor) | 10 ms; 31 ms when no word matches |
| The grid going from every symbol to a search's results, laid out (main actor) | 21 ms, of which SwiftUI's buttons about 10 and their tooltips 2.5 |
| A screen of 63 symbols drawn from kept `NSImage`s | 22 ms: a symbol costs 0.35 ms each time it is drawn |

## Decision

1. **The catalogs are read once and kept while a picker may want them** (`IconLibrary`): dropped two minutes after the
   last picker closed. What a symbol is found by (the words of its name and of its search words) is made when it is read.
2. **What is found is kept until the search changes**: the picker no longer searches at each redraw.
3. **The grid is one view that draws itself** (`IconGridView`): only the cells of the part asked for, the cell under the
   pointer found by arithmetic (`IconGridLayout`). Nothing is made for the thousands of cells out of sight.
4. **Icons are drawn from pictures rendered once, off the main actor** (`IconPictures`). Drawing never waits: an icon not
   rendered yet is left out and the view is drawn again when it is there; those in sight first, then three screens ahead
   and one behind.
5. **Emoji are offered beside symbols**: one search over both (symbols first), a Symbols / Emoji choice when nothing is
   typed. Their names are the system's (`CoreEmoji`, 1,919 of them); the Character Viewer is still a button away.
6. **To accessibility the cells in sight are buttons by name** (`IconGridCellElement`): the grid has no view for each.

## Measured after (same harness)

| What | Before | After, p50 (p90) |
| --- | --- | --- |
| A search, per key | 10 ms | 0.5 ms; 14 ms when no word matches and the loose match runs |
| The list changed, laid out and drawn | 21 ms laid out only | 0.35 ms (0.56) |
| A scroll step of two rows drawn, symbols | 22 ms from kept images | 0.42 ms (0.50), never drawn before or not |
| The same, emoji | 3.9 ms (18) as text | 0.76 ms (1.0) |
| Until the symbols in sight are there, after the list is shown | drawn at once, at the cost above | 15 ms; 0.7 s the first time in the test process |
| Kept in memory | nothing between openings | 2.6 MB of catalogs while kept; pictures 5 to 9 KB each, 400 at most |

## Found on the way, and why pictures and not masks

- A system symbol draws nothing into a grey bitmap. A first test passed all the same, on the padding bytes of the rows;
  the test now reads painted pixels.
- A mask (a byte a pixel, any colour) was the first choice. On screen a view is drawn into a context that records, and
  there a clip to a mask painted nothing, and a stencil drawn as an image left the whole view blank in most launches, even
  for the emoji drawn beside. Plain coloured pictures are drawn as any image is; they are redone when the appearance changes.
- Overriding `scrollWheel` in the grid turned off AppKit's drawing ahead of the scroll; the pointer is followed from the
  clip view's bounds instead.

## Not done

- **Emoji have no categories and no skin tones**: the system's names are readable, its order and groups are not. They
  are listed faces first, flags last, by where Unicode has them.
- The loose match on symbols (14 ms) still runs on the main actor when nothing else matches.
- Hovering a cell names it under the grid; there is no tooltip.
- Not measured on screen: the numbers are of drawing into a bitmap in a test. Not seen: scrolling by hand.
