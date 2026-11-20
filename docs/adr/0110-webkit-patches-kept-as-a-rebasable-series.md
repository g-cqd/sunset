---
status: proposed
date: 2026-11-20
---

# ADR-0110: Our WebKit patches are a small series that moves to a new WebKit mechanically

## Context

The owner, 2026-11-20: "we should definitely investigate patching webkit for our usage"; "applying patch to a new version of
webkit should be a straightforward operation and safe". The first candidates are W1–W6 (roadmap 0048 D,
`docs/research/webkit-extension-patches-2026-11-20.md`) and the resolver (t13). ADR-0078 still holds: our own WebKit ships only
when shown better.

## Decision

1. **A series, not a fork.** Each patch is a `git format-patch` file in Sunset's repository (`Engine/WebKit/patches/NNNN-*.patch`),
   applied on a named WebKit commit written next to it (`Engine/WebKit/base`). No WebKit tree is kept or vendored; a script
   fetches the base, applies the series, builds.
2. **One concern per patch, as small as it can be**: a patch touches the fewest files, prefers a generator or an IDL line to
   generated code, adds no reformatting, and says in its message which defect (W1…) it fixes and how it is tested.
3. **Moving to a new WebKit is one command**: fetch the new base, `git am -3` the series (three-way, so a moved line merges
   itself), `rerere` on, stop at the first patch that does not apply, with its name. A patch that no longer applies is
   rewritten, never forced; a patch that WebKit has made unneeded is dropped.
4. **Safe means tested**: each patch has its probe (Sunset's test, or one of WebKit's own tests it adds) run against the
   patched build after every move; a move is not taken until all pass, and WebKit's own tests for the touched area pass too.
5. **Upstream first where it can go**: generic fixes (W1–W3) are offered to WebKit; each one accepted leaves the series.
   What stays is what only Sunset wants (blocking `webRequest`, the resolver).
6. **Base**: a WebKit commit that builds and passes its touched tests; moved on a cadence and at every WebKit security
   release, so a security fix never waits on our series.

## Consequences

- The cost of the series is measured at each move (time to rebase, patches rewritten); a series too costly to move is a
  reason against our own WebKit (ADR-0078).
- `Scripts/webkit.sh` (fetch, apply, build, move, export) is the one command; a move that does not apply leaves the base
  where it was (seen, diary 2026-11-20-17). Nothing is built yet; the spike (roadmap 0048 B) checks the build and the first
  real move.
