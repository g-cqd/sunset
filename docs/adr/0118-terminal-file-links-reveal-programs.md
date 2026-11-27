---
status: accepted
date: 2026-11-22
---

# A terminal's link to a program is shown in the Finder, not run; a setting says otherwise

## Context

A program's output can hold a link (OSC 8) to a file of this Mac and label it as anything. A Cmd-click handed it to the
system, which opens it: an app starts, a `.command` script runs in Terminal. The text can come from anywhere (a log, an ssh
session, a file shown with `cat`). The outside audit of 2026-11-22 (LOW-05; their dynamic report: medium) showed it.

The owner, asked (2026-11-22), wanted a setting.

## Decision

- `terminal.fileLinks`: `revealPrograms` (the default), `open`, `reveal`. Under Terminal › Programs, with what programs may do.
- A program is what the system runs, starts or installs when it is opened: an app, an executable file, a script Terminal or
  Automator runs, an installer, a Java archive, and the kinds macOS itself calls unsafe (`LSRiskCategoryUnsafeExecutable`
  in CoreTypes.bundle) (`FileLinkTarget`). Symbolic links and Finder aliases are followed to what they name first (Launch
  Services opens an alias's target); a link whose target cannot be found is treated as a program.
- `revealPrograms`: a program is selected in the Finder; anything else opens as before.

## Consequences

- The common case (a file a compiler or grep printed) opens in one click; a program takes a second, deliberate one.
- The list of program kinds is a list: a kind it misses opens. `open` restores the old behaviour.
