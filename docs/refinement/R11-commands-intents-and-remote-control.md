# R11 — Commands, keys, the command bar, App Intents and remote control (roadmap 0018)

Status: **two rounds answered (2026-11-11); the outcome below is to be read and accepted by the owner.** Nothing here is built.
Input: the owner's notes in R6, note n1, `docs/research/remote-control.md` (ADR-0022 proposed), R1 and R4 (configurable keys).
As built today: about 25 actions written by hand in menus with fixed keys; a command bar (Cmd-L) that searches tabs.

## The owner's answers

| Question | Answer | His note |
| --- | --- | --- |
| The command model | Every action is declared once, and everything is generated from it: menus, keys, the command bar's list, App Intents, the remote channel | |
| Where keys are set | The configuration file and a Settings pane | |
| Shortcuts and the terminal | Any combination, no warning | |
| Two-step shortcuts | Yes | |
| Parameters in a binding | Yes: send text, a new tab at a directory, open an address | |
| The address field and the command bar | Two different things | |
| What the command bar finds | Open tabs in every Space; actions; Favorites and Pinned, open or not; Spaces and profiles; addresses, history, web search; documents and recent files; settings | |
| Matching | Words and initials, tolerant of typos, ranked by kind, recency and learning; plus a study of semantic matching | |
| Learning | Typed letters to the chosen item | Might be a candidate for encryption |
| An action needing more | The bar asks in a second step | |
| Intents offered to the system | Open things; navigate; arrange; run a command in a new terminal; type into an existing terminal; read a terminal's text or a page's address | |
| The risky intents | Off until turned on in Settings, a switch per class; then free | |
| Spotlight | Actions, Favorites and Pinned, open tabs and Spaces | |
| Remote channels | A local socket and a `sunset` command-line tool; an MCP server for agents; XPC; AppleScript | Staged in time by what is really likely to be used |
| Who may connect | Off by default; on in Settings; then any program of the user's | |
| What a client can do | Observe the layout; read terminal text; type into terminals; wait for events; drive pages | |
| While something drives a pane | Always a mark on the pane and its tab, with a stop control | |
| Where an agent works | Wherever it is granted | |
| When | All of it after the pane work | |
| Order among its parts | The model and keys; the bar; intents; the socket and tool; MCP; the rest | |

## The outcome, as one description

**Commands.** Every action of the app is declared once: an id, a title, its parameters, when it is available. The menus, the shortcuts, the
command bar's list, the App Intents and the remote channel are generated from that table, so an action cannot exist in one place and be
missing in another. Shortcuts are settings, in the configuration file and in a Settings pane that records them; they may be any combination,
single or two-step, and a binding may carry parameters (text to send, a directory, an address).

**The command bar** is separate from the pages' address field. It finds open tabs in every Space, actions, Favorites and Pinned entries,
Spaces and profiles, addresses and history and web search, documents and recent files, and settings. It matches word starts and initials,
forgives a wrong letter, and ranks by kind, recency and what was chosen before for the same letters. An action that needs something more asks
for it in a second step in the bar. Semantic matching is a study, read back before it is added.

**App Intents.** The system can open things, navigate, arrange, and, each behind its own switch that is off until turned on: run a command in
a new terminal, type into a terminal, read a terminal's text or a page's address. Actions, kept entries, open tabs and Spaces are findable
from Spotlight.

**Remote control.** A local socket with a `sunset` tool first, then an MCP server over it, then XPC and AppleScript as they prove wanted. It is
off by default; once on, any program of the user's can connect. A client can observe the layout, read terminal text, type into terminals, wait
for events and drive pages. A pane being driven always shows it, on the pane and its tab, with a control that stops it.

All of it is built after the pane work, in this order: the model and keys, the bar, intents, the socket and tool, MCP, the rest.

Costs, as the owner asked to see them.
- **Security.** These are the owner's choices with their consequences. *Any shortcut, no warning*: a binding without Command takes that key
  from terminal programs silently. *Risky intents free once on*: any Shortcut, including one downloaded, can then run a command with the
  user's rights, type into a root shell or an ssh session, or read a screen and send it elsewhere. *Remote on for any program of the user's*:
  one switch gives every program run by the user every terminal and every page; nothing bounds an agent to a pane. The mark and the stop
  control are what remains to see and end it. *Open tabs in Spotlight*: tab titles, which carry directories and page titles, are indexed by
  the system. *Learned letters*: a small local file of typed fragments; the owner flags it for encryption (study t135).
- **Speed.** Key lookup runs on every key down: a table lookup, two-step state included; measured when built since it is on the input path.
  Matching a few thousand items takes microseconds.
- **Memory.** The table and the learned ranking are small. Semantic matching would load a language model (tens of MB, unmeasured): hence a study.
- **Safety.** One declaration, one path: menus, keys, bar, intents and remote all run the same code, tested once.

## Said plainly

- **Built after the pane work**, so folders, pages, Markdown and Spaces write their menus and fixed keys by hand as today, and are moved onto
  the table later: that part is done twice. R1 and R4 asked for configurable keys: until this is built, their keys are fixed.
- **Arrange was not granted to remote clients**, but R6's "command from the shell that opens a file in a pane" (t171) is an arrangement. As
  answered, the `sunset` tool could not do it. I ask at that step whether opening is allowed, rather than assume.
- The command bar finds addresses and history although the address field is a different thing: typing an address in the bar opens a page;
  the two share R1's rules for what is typed. If that is not what was meant, say so.
- Whether Sunset can know which Shortcut calls an intent is unverified; the answer chosen (a switch per class) does not depend on it.
- The in-band channel (escape sequences from inside a terminal) was not chosen: nothing a terminal prints can drive Sunset.
- Not asked, left for the steps: default keys, the exact list of commands, bounds on reads, the events' list, the tool's syntax.

## Steps proposed (each begins with its own questions)

| Step | What | Questions still to ask |
| --- | --- | --- |
| C-1 | The command table; today's actions and those built since moved onto it; menus generated | How a menu's layout is declared; where the table lives (`SunsetShell` or its own target) |
| C-2 | Keys as settings: the file's section, the Settings pane with a recorder, two-step sequences, parameters in a binding | Defaults; the pending-sequence indicator; timeout |
| C-3 | The command bar: the seven kinds of results, matching, ranking, learning, the second step | What a result row shows; how learning is cleared |
| C-4 | App Intents: open, navigate, arrange; the three risky classes behind switches; Spotlight | Which entities; wording of the switches |
| C-5 | The local socket and the `sunset` tool: observe, read, type, wait | Syntax; bounds; whether opening is allowed (t171) |
| C-6 | The mark on a driven pane and its stop control | Sketches |
| C-7 | The MCP server over the socket; pages driven (t136) | Tools' list |
| C-8 | XPC and AppleScript, when wanted | |
| Study | Semantic matching in the command bar, read back | |
