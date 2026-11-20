---
status: accepted
date: 2026-11-20
---

# 0107 — Seven tests are checked on macOS 27 only, behind one trait

## Context

CI's runner is macOS 26 (`macos-26-arm64`), Sunset's deployment target; both Macs Sunset is written on run macOS 27.2. Once
CI built again (the 26.5 SDK fix), seven tests failed there and pass here: drawn pixels (the sidebar's separators, the icon
grid), text layout (the address field's first visible point, 3 vs 2), WebKit loading a page from the test's own server
(three user-agent tests), and a click on a favourite. None of it reproduces on a Mac this repository has (diary 2026-11-20-08).
The window's corner radius, the eighth failure, was a fact about each system and is now expected per system.

## Decision

The owner chose (2026-11-20) to run those seven on macOS 27 or later only: `@Test(.macOS27)`, a `ConditionTrait` in
SunsetTestSupport whose skip says why and names task t129. Nothing else gets it without a failure on macOS 26 seen first.

## Consequences

- CI can be green on macOS 26 without these tests; what they check is **not tested on macOS 26**, which Sunset still
  supports. Task t129 holds the list; removing the trait from a test needs a macOS 26 run of it (a VM or a 27 runner gone).
- Alternatives not taken: a macOS 26 virtual machine here (slowest, most honest), or CI on macOS 27 only (26 untested
  everywhere).
