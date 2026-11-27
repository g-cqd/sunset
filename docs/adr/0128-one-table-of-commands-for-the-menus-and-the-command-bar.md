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

- A command's key can be set (`keys` in the file: a command's name and its key, written "cmd+shift+d" or as the menus
  write it; "" takes its key away). `CommandKeys` holds the keys in force: the file's, else the table's unless the file
  gave that key to another command. Names that are not commands and keys without Command or Control are reported as
  issues of the file. Settings › General › Keyboard shortcuts records a key by pressing it (`KeyRecorder`); a key given
  to one command is taken from the one that had it.

- The command bar ranks the commands it finds: those whose title has every typed word first, then by how often each
  was run from the bar. It learns the command a query ran (`CommandLearning`): typed again, that command is the first
  row, before the tabs and what the web would do. Only words typed to find a command and the counts are kept, in the
  app's defaults (at most 200 queries).

Two-key sequences and commands with parameters are not done.

Items whose list is made at run time (the Spaces by name, Tab 1 to 9, the Format menu, history entries, Keep Awake)
stay as they were.

## Consequences

A command has one title and one key wherever it is offered, and each key is used once (`AppCommandTableTests`,
`CommandKeysTests`). A command bar that ranks and learns, and the outside channels, read this table.
