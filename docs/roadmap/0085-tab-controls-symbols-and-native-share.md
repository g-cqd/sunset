---
status: done
blocked-by: nothing
date: 2026-11-19
---

# 0085 — A tab's controls, its symbols, and sharing a screen natively (the owner, 2026-11-19)

| Step | What | Status |
|---|---|---|
| A | Share: the asking tab offered in its Space, "(this tab)" | done (tested) |
| B | Share: "Screen, Window or App…" is macOS's picker, Sunset captures what is picked (ADR-0085); WebKit's silent capture refused | done; the picker seen coming up, a pick and its frames not seen |
| C | Sound, microphone, camera as a sidebar row's buttons at its end, the cup's size, after the cup (`RowEnd`, `RowEndButton`) | done (geometry tested); not seen |
| D | The site panel: "This tab now" (sound, devices, stop capture, stop sharing) apart from the site's settings | done; not seen |
| E | The cup's slash as SF Symbols' own (`SlashedSymbol`: a gap cut on both sides, the stroke a tenth of the size) | done, drawn beside SF's four and compared |
| F | The folder with its initial at a tab symbol's size (13 pt, not 15) | done (tested, drawn) |
| G | One weight per role: controls `Design.Symbol.weight` (semibold), pictures regular; the bar's sound and devices at the controls' size | done (tested over the sources) |

Not done: none of it seen in the app (the terminal lost accessibility and screen recording); the top bar keeps its sound and
devices inline (at the controls' size and weight now), not as buttons at the tab's end; system audio is not shared.
