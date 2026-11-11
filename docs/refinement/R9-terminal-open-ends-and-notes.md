# R9 — The terminal's open ends, old decisions and the owner's notes (roadmap 0018)

Status: **two rounds answered (2026-11-11); the outcome below is to be read and accepted by the owner.** Nothing here is built.
Input: tasks t58, t108, t94, t55, t77, t40, t54, t17, t19, t100, t141; the acknowledged notes.

## The owner's answers

| Item | Answer |
| --- | --- |
| Search in the scrollback | Build: plain text and regular expressions |
| Conformance (margins, esctest, vttest) | The gap list first, read back, then fix by it |
| Fuzzing | Study the tooling, then build |
| Images | A design session of its own, then kitty graphics |
| Colour (n10) | Measure first what is wrong today, on his displays; then fix by the findings |
| Fonts (n2) | Settings for a font per style, fallback order and variable axes; and a study of an own font stack |
| OSC 21 | Build |
| OSC 66 | A design study first |
| bash shell integration | Build |
| The prompt lower after a resize (n29) | Leave as it is |
| The survey of other terminals (n18) | Do it |
| Remote control (n1) | Refined inside R11, with the command model |
| CI | Stays waiting: nothing is pushed |
| Performance | After all the pane work, with the terminal items |
| Aemi (n17, promotions) | "Worked on whenever we need it" |
| Linux | Much later |
| ADR-0007 | Confirmed: the tip handed back is what must build and pass |
| Studies | They wait with the rest: one thing at a time, in the order set |
| Terminal work in the order | After all of it (folders, web milestone, Markdown, Spaces, profiles, web beyond, restoring) |
| Order among the terminal items | Small builds, then measurements, then the large designs |
| The acknowledged notes | "Review that yourself and address them accordingly" |

## The outcome, as one description

After the pane work, the terminal's items come in this order. **Small builds**: OSC 21; shell integration for bash; search in the scrollback,
plain and by regular expression. **Measurements, each read back**: the esctest and vttest gap list, then fixes by it (left and right margins
among them); colours measured on the owner's displays in both renderers, then fixes by the findings; the survey of other terminals' features.
**Then** the font settings (per style, fallback order, variable axes). **Then the large designs, each a study or a session first**: fuzzing
tooling; images (a design session, then kitty graphics); OSC 66; an own font stack. Performance is taken up again with these.

Remote control is decided inside R11. CI waits. Aemi's slimming and promotions are done when Sunset needs one of them. Linux is much later.
The prompt sitting lower after a resize is left as it is.

Costs, as the owner asked to see them, where an answer carries one.
- **Search**: scans packed history on demand, off the main thread, nothing kept between searches; a regular expression over a million lines is
  bounded in time (safety). Whether AemiRegex fits is unverified and checked first.
- **bash integration** sits in the shell's startup: behind the existing setting, tested against the installed bash.
- **Images, OSC 66**: both must cost nothing on the text path when unused; that is the first requirement of their designs.
- **CI waiting**: the 180-odd commits exist on one disk only. Said once more because it is a safety matter; the owner decides.
- **Performance after everything**: nothing re-measures speed while the pane work goes on, so a slowdown introduced there would be found late.
  I measure a step when it touches the terminal's drawing or input path and report it (a defect in what I just built is mine to fix, §10).

## The notes, reviewed as the owner asked

| Note | State | Why |
| --- | --- | --- |
| n3 lint strict on safety | fulfilled | SwiftLint forbids force try, force cast, force unwrap, implicitly unwrapped optionals; in the commit hook |
| n4 quality rules consolidated | fulfilled | One top-level type per file, 250 lines a file, bounded bodies: lint and a test |
| n7 no GCD | fulfilled | Zero uses of Dispatch in `Sources` (searched 2026-11-11) |
| n5 the whole OSC scope | fulfilled | Answered: all handled but OSC 21 (to build) and OSC 66 (a study) |
| n19, n20 the Arc study | fulfilled | Done on mbp23; its ideas went through R3 and R4 |
| n29 prompt after resize | fulfilled | The owner's answer: leave as it is |
| n1 remote control | acknowledged | Goes into R11 |
| n8 modern APIs, SwiftUI and AppKit each where relevant | acknowledged | A standing rule, never "done" |
| n10 colour accuracy | acknowledged | The colour measurement above |
| n11 RAM a bit high | acknowledged | Renderer memory was reduced; not re-measured today; the rest is with performance |
| n17 Aemi | acknowledged | "Whenever we need it"; the audit is `docs/research/aemi-audit-2026-11-08.md` |
| n18 survey | acknowledged | The survey above |
| n40 to n46 | acknowledged | Each is a roadmap now (0019 to 0024); fulfilled when built |

## Steps proposed (each begins with its own questions)

| Step | What |
| --- | --- |
| T-1 | OSC 21 |
| T-2 | Shell integration for bash (and the directory report from the taught zsh, left from t108) |
| T-3 | Search in the scrollback: plain and regular expressions |
| T-4 | The esctest and vttest gap list, read back; then fixes by it |
| T-5 | Colours measured on the owner's displays, read back; then fixes |
| T-6 | The survey of other terminals, read back |
| T-7 | Font settings: per style, fallback order, variable axes |
| T-8 | Study: fuzzing tooling; then the fuzzer |
| T-9 | Images: a design session; then kitty graphics |
| T-10 | Study: OSC 66 |
| T-11 | Study: an own font stack |
| P | Performance, taken up again (t100) |

I placed the survey with the measurements and performance last; the owner can move them.
