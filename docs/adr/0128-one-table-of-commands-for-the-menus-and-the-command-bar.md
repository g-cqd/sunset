# 0128: One table of commands for the menus and the command bar

## Context

The menus wrote each command's title, key and action where the item was made, and the command bar had a list of its
own: only eight commands (Settings, Help, Import, the Library's lists) and none of the menus' others. Making keys
settings, adding commands to the command bar, and driving the app from outside (a socket, App Intents) each need the
commands as data.

## Decision

`AppCommand.table` (`SunsetShellModel`) lists the app's commands: an identifier, a title, a symbol, the menu it is in,
its key (`KeyChord`), its scope and the words that find it. It has no AppKit or SwiftUI.

- The menus make their items from it (`CommandItem`): the title (or one for the state it is in, as "Unmute Page"), the
  key, and whether it is enabled come from the table and `AppCommandRunner`.
- `AppCommandRunner` runs a command: from a menu on what has the keyboard, from the command bar on what the acting
  window shows; it says whether a command would do something now.
- The command bar offers every command of a scope that is on whose words start with every typed word (two letters at
  least), enabled now, with its menu and its key beside it (`CommandRows`).

Items whose list is made at run time (the Spaces by name, Tab 1 to 9, the Format menu, history entries, Keep Awake)
stay as they were.

## Consequences

A command has one title and one key wherever it is offered, and each key is used once (`AppCommandTableTests`). Keys as
settings, a command bar that ranks and learns, and the outside channels read this table.
