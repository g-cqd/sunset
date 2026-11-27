# 0130: Shortcuts, Spotlight and Siri run the menus' commands

## Context

The command table (ADR-0128) names every command of the menus. The system's own ways of running an app's actions
(Shortcuts, Spotlight, Siri) read App Intents, which the app declares in its own target so that Xcode extracts their
metadata.

## Decision

- `RunSunsetCommand` (`Sources/SunsetAppMain/RunSunsetCommand.swift`) runs one command, a `SunsetCommand` entity, in the
  window in front, as the command bar does; it opens the app. The commands are those of the scopes that are on, found by
  the words of their title. `SunsetShortcuts` offers it to Spotlight and Siri without a shortcut made.
- The intents reach the app through `AppIntentBridge` alone: the commands' names and titles, and running one. Reading
  a pane or typing into one stays the control socket's, behind its switches (ADR-0129).

## Consequences

Each command added to the table is offered to Shortcuts at once. Intents that read or type are not offered.
