# 0129: The app asked from outside, over a socket only its user can open

## Context

Scripts and agents should be able to see what Sunset shows and act on it: list the panes, read a terminal's screen,
type into it, wait for a prompt, run the menus' commands. Each of these is a way in for a program the person did not
mean to trust, so each must be asked for.

## Decision

- `SunsetControl` (no AppKit) holds the protocol and the socket: one line of JSON per request (`ControlRequest`: list,
  read, type, wait, run, commands) and one per reply (`ControlReply`). Lines longer than 1 MiB are not read.
- The socket is `~/Library/Application Support/Sunset/control.sock`: its folder is made 0700, the socket 0600, and a
  peer whose user is not the app's (`getpeereid`) is closed without an answer.
- `control.enabled` (off) opens the socket: listing and reading panes, running commands of the table (ADR-0128), waiting
  for a text on a terminal's screen (at most ten minutes). `control.typing` (off) also lets it type into terminals, as
  keys are typed. Both are in Settings › General › Control from outside.
- `sunset` (`SunsetControlTool`) is the command-line end: `sunset list`, `read [PANE] [--lines N]`, `type PANE TEXT`,
  `wait PANE TEXT [--timeout S]`, `run COMMAND`, `commands`; `--json` prints the reply. A pane is an id from `list`, or
  `shown`.

- A pane the tool reads, types into or waits on is marked on its tab for ten seconds after the last request
  (`DrivenPanes`); pressing the mark stops it: the tool is refused that pane until the app quits.

- `sunset mcp` is an MCP server on standard input and output (`MCPBridge`): its tools (list_panes, read_pane,
  type_into_pane, wait_for_text, run_command, list_commands) are these requests, and what the app refuses is the tool's
  error. An agent is given Sunset by naming `sunset mcp` as a server.

## Consequences

The tool is built with `swift build --product sunset`; it is not yet inside the app's bundle. Streaming what a pane
does (observe) is not done.
