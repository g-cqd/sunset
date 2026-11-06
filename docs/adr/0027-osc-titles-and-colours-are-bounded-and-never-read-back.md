---
status: accepted
date: 2026-11-05
---

# 0027 — OSC: titles and colours, bounded, sanitised, and never read back

## Decision

- The sink learns how a string ended (`StringTerminator`: BEL, ST, or none), so a reply ends the way its query did.
- OSC payloads are buffered up to 4096 bytes; a longer one is dropped whole. Only completed strings act (CAN/SUB cancel). DCS, APC, PM and SOS are never read as OSC.
- **Titles** (OSC 0, 1, 2): control characters (C0, DEL, C1 as UTF-8) are removed on the way in; titles are **never reported back** (ADR-0026). A title stack (CSI 22/23 t) keeps ten.
- **Colours**: OSC 4 and 104 (palette), OSC 10/11/12 and 110/111/112 (default foreground, background, cursor), queries answered as `rgb:RRRR/GGGG/BBBB`. X colour forms `rgb:` (1-4 hex digits per component) and `#` (1-4 digits): one digit is repeated, wider components keep their high eight bits (X's rule, as the terminals following it do). Palette resets go back to the host's seed (`Palette(colors:foreground:background:cursor:)`), by default xterm's colours.
- **Since ADR-0010 (accepted 2026-11-06)**: OSC 52 write, 7, 9, 9;4, 99, 133, 777 and 1337 (SetMark, CurrentDir) are handled under its policy; OSC 8 (hyperlinks) is still ignored.

## Evidence

104 tests pass. The new tests were written against stubs and failed (33 issues) before the implementation. A hand-made mutant sweep of the OSC code (nine mutants, restored from a copy each time): eight were caught at once, one survived (other string kinds treated as OSC), a test was added and the mutant is now caught.

## Not established

Named X colours (`red`, `rgb:` with `rgbi:`) are not parsed; the xterm behaviour for malformed pairs in a multi-pair OSC 4 is not compared with the oracles; the 4096-byte limit is my choice; no benchmark of the OSC path since titles now allocate nothing but the replies queue still grows on demand.
