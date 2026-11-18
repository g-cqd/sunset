---
status: accepted
date: 2026-11-18
---

# 0076 — Hidden pages are unloaded under pressure at macOS's critical level only

Supersedes point 3 of ADR-0071 on one word: "warning or critical" becomes "critical".

## Context

ADR-0071 unloads the page hidden the longest, one a minute, "while macOS's pressure level is warning or critical". On
the owner's Mac on 2026-11-18, `kern.memorystatus_vm_pressure_level` read 2 (warning) in every sample for minutes, with
48 % of the memory free (`memory_pressure -Q`). The warning level is where macOS compresses, and it can last: with it,
Sunset unloaded a hidden page every minute, and a page shown again was loaded again, without what its scripts held
(scroll inside the page, what was open in it). The owner: a tab shown again "does not always keep its exact state"
(roadmap 0045 A).

## Decision

Memory is short at the critical level (4) only (`PageSleep.memoryIsShort`). `web.unloadUnderPressure` and the delay
(`web.unloadAfter`) are unchanged.

## Consequences

Fewer pages unloaded; a Mac that stays at the warning level keeps every page until the delay. Whether the critical level
comes soon enough to spare the system is not measured.
