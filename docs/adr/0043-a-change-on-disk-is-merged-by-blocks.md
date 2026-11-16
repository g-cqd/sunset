---
status: accepted
date: 2026-11-16
---

# 0043 — A change on disk is merged into the edits made here, block by block, and never by a guess

Roadmap 0023, step M-e. R6 decided the principle (reloaded silently if unedited, merged by Markdown nodes if edited,
conflicting nodes asked about) and named the risk: **a wrong merge is silent damage**. The owner answered on 2026-11-16 how
it is shown; this says how it is done, and where it stops.

## Decision

1. **Three texts.** What the file held when this text was last what the file said (the base, now kept: one more copy of the
   text in memory for every open file), what is here, what the disk says now.
2. **Pieces.** Markdown is cut where its top-level blocks begin, as the parser reads it with the page's extensions; a piece
   is a block and the blank lines after it. Text and Mermaid are cut at their lines. The pieces joined are the text, byte
   for byte, and two pieces are the same when their bytes are (a file changed from a composed to a decomposed character
   did change).
3. **What is done without a question** is narrow: pieces that only the disk replaced, removed or put in, where the pieces
   here are exactly the pieces of before. Changes to blocks side by side are both kept (a block is a unit; this is where
   merging by blocks is better than by lines). A run replaced by as many pieces is one change for each piece, so a question
   is about one block.
4. **A conflict** is: the same piece changed on both sides, pieces put in at the same place by both, or pieces put in among
   those the other side replaced; unless both made the same of it. Mine stays in the text; the disk's is kept beside it.
5. **What was merged is read again.** A block is what it is because of what stands before it (an indented line is code
   after a paragraph, a part of the item after a list item). If the merged text does not read as exactly the blocks that
   were chosen, nothing is merged and the whole text is one conflict. This is the check that makes point 3 safe to widen.
6. **Comparing is bounded.** The common start and end are set aside; pieces that occur once on each side hold the rest
   together; between them pieces are compared in full within a budget (a million pairs a side, some 35 ms at worst), then
   place by place, else the run counts as replaced. Past the budget the result is a larger conflict, never a wrong merge.
7. **Shown as the owner chose** (sketch A): on the block, in the document, in both views. In the source the text itself is
   tinted and a card under the block holds the disk's and the three answers (Keep Mine, Keep Disk's, Keep Both); on the
   page both are drawn, one above the other. A bar counts them, with previous and next.
8. **Nothing is written while a conflict waits**: `save` refuses (Cmd-S shows the first conflict), the document does not
   save itself, Save in the sheet on closing closes nothing, Save All at quit names it.
9. **The merge is one step of undo**, and is said for a few seconds with Undo; the blocks it put in are tinted for a
   moment. Undone, the text is as it was, and saving then writes it over the disk's blocks.
10. **Edited or not, after a merge**, is told by comparing the text with what the file holds: the text's own count of what
    was saved is of the file of before. (Undone back to that old text, it is still edited.)
11. A text of more than 262,144 UTF-16 units is compared off the main actor, and what was found is used only if nothing
    moved meanwhile.

## Measured (release, this machine, `DocumentMergeBenchTests`)

| Document | Blocks | A merge, p50 | Of which one text cut into blocks |
|---|---|---|---|
| 20 KB | 186 | 1.0 ms | 0.18 ms |
| 200 KB | 1,846 | 9.8 ms | 1.8 ms |
| 2 MB | 18,341 | 97 ms | 17.7 ms |
| 10 MB | 91,446 | 485 ms | 88.8 ms |

Every block changed on both sides: 283 ms at 2,000 blocks with the standard library's comparison alone; 3 ms once pieces
that are plainly the same hold it together and a budget bounds the rest.

## Where it stops

- The parser reads four texts for a merge (three, and the merged one). Nothing is reused from the session the editor keeps.
- No word-level merge inside a block, and no view of what changed inside the two versions.
- Documents of Sunset's own store are not merged: nothing else writes them.
- In the kit, `MarkdownSource` cannot be told that another text is the saved one; hence point 10. To propose there.
