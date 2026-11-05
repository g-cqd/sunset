# Remote control of the terminal (owner note n1, 2026-11-05)

Question: the terminal should be drivable remotely, completely, "through MCP, or CLI, or XPC"; AI agents would benefit from a stdio MCP server; not the utmost priority. What is the best way?
Labels: **[read]** source or docs read today, **[recalled]** from memory, unchecked, **[unverified]** a proposal.

## 1. What the others do

| Terminal | Mechanism | Evidence |
|---|---|---|
| **kitty** | JSON commands, `ESC P @kitty-cmd<JSON> ESC \` **written to the tty itself** (no socket needed; works from inside the window, even over SSH), or over a unix socket (`--listen-on`, `allow_remote_control=socket-only`); `kitten @` is the CLI with on the order of a hundred subcommands (113 indented help lines). Authorisation: `allow_remote_control` modes, and `remote_control_password` entries that can be limited to **glob-matched actions** (`get-colors`, `set-tab-*`, …) or to a custom Python checker; with a password the command is **encrypted** (ECDH public key + AES-256-GCM, timestamped) | [read] `docs/rc_protocol.rst`, `docs/remote-control.rst`, `kitty/options/definition.py`; `kitten @ --help` |
| **WezTerm** | `wezterm cli`: about 19 commands (list, spawn, split-pane, send-text, get-text, activate-*, kill-pane, set-tab-title, adjust-pane-size, zoom…) talking to the **mux server** over a unix domain socket | [read] `wezterm cli --help`, `docs/cli/cli` |
| **Ghostty** | on macOS an **AppleScript** dictionary (input text, key events, mouse button/position/scroll; window, tab, terminal records) and **App Intents**; no control CLI for a running instance that I found | [read] `macos/Sources/Features/AppleScript/*`, `Features/App Intents` (file names only; behaviour unread) |
| **iTerm2** | scripting API over a websocket on a unix socket, protobuf messages; AppleScript | [recalled] |
| **tmux** | control mode (a text protocol on stdin/stdout) | [recalled] |
| **Alacritty** | `alacritty msg` (create-window, config) over a unix socket; very small | [recalled]; not checked |

What stands out: kitty is the most complete and has the only **in-band** channel and the only real **authorisation model** (per-action globs, encrypted passwords). WezTerm's CLI is a thin client of a **mux server**. Ghostty's is a platform scripting surface, not a protocol.

## 2. What an agent needs (from how agents drive terminals) [analysis]

- **Observe:** screen text (visible region, any scrollback range), cursor, size, modes (alt screen, mouse, bracketed paste), title, working directory, foreground process, **semantic zones** (OSC 133: last prompt, last command, its output and exit status), and images/hyperlinks metadata. Reading by *zone* ("output of the last command") is what makes this cheaper and more reliable than screen scraping.
- **Act:** send text as typed or as paste (bracketed when the program asked for it), send keys by name (with the kitty keyboard protocol's modifiers), resize, spawn/split/close/focus windows and tabs, set title, scroll, select and copy.
- **Wait and subscribe:** "output idle for N ms", "command finished" (OSC 133 D), "bell", "title changed", "process exited", "screen contains regex"; without events an agent polls and burns tokens.
- **Stable identity and scoping:** window/tab/pane ids, optionally limited to a subtree an agent was given; a way to run an agent's work in a window the user can watch.
- **Bounds:** maximum bytes per read, rate limits, backpressure; reads that cannot be huge.
This is, almost exactly, roadmap 0004's headless orchestration API (spawn, keys, resize, snapshot, replies, recording). **Remote control is that API reached over a transport**, which argues for building the API first and the transports as adapters.

## 3. Transports compared [analysis]

| Transport | Good for | Costs |
|---|---|---|
| **Unix-domain socket + CLI (`sunsetctl`)** | scripts, humans, CI; Linux and macOS; peer credentials (`LOCAL_PEERCRED`/`getpeereid`); trivially testable; the base for every other adapter | a protocol and a client of our own (AemiProtobuf and AemiJSON already exist for both encodings) |
| **MCP over stdio (`sunsetctl mcp`)** | agents: the agent host spawns it and sees the terminal as tools and resources; the largest audience, in a standard form | MCP is a moving spec; an **adapter** over the socket, not a second implementation; ask has an MCP **client** only (`AskMCP`, 41 files); wire and envelope types would be promoted to an Aemi package so both sides share them |
| **XPC (macOS)** | native integrations: code-signature-verified peers (audit token), sandbox-friendly entitlements, launchd activation, later App Intents/Shortcuts | macOS only; no Linux story; a second surface to keep equal to the first |
| **In-band (kitty-style DCS/OSC from inside the window)** | a program (or an agent's shell) controlling *its own* terminal, including through SSH, with no socket; kitty compatibility | any program that can print can attempt it: needs per-window opt-in and per-action authorisation; screen-reading in-band means output goes back down the pty |
| HTTP/WebSocket (the `HTTP` package) | remote machines, browsers | a network attack surface; not needed first |

## 4. Proposal (all [unverified]; ADR-0022 is **proposed**)

1. **One typed, versioned command model** is the source of truth (observe / act / wait, with ids and bounds), defined once; encoded as protobuf (AemiProtobuf) on the wire and as JSON for humans and agents (AemiJSON); the headless core implements it in process.
2. **Socket + CLI first**, then **`sunsetctl mcp`** (stdio) as a thin translation of the same commands into MCP tools/resources, then **XPC** on macOS. In-band control, if wanted, is a fourth adapter, off by default, kitty-compatible for the subset that makes sense.
3. **Authorisation is part of the model, not of a transport:** a capability is *(scope: window set) × (action globs) × (read limits)*, as kitty's per-action globs show it can work; sockets live in a per-user 0700 directory and check peer credentials (XPC: audit token and code signature); the terminal injects `SUNSET_LISTEN_ON`, `SUNSET_WINDOW_ID` and a per-window token into each shell's environment so a process can control *its own window* without configuration; wider scopes need a user grant (prompt) and are listed and revocable in the UI; every request is logged.
4. **Defaults deny:** off until enabled; reading screen contents is a separate grant from sending input (an agent that may type must not silently be able to read a password prompt that the user is typing into another window); OSC 52/clipboard and file-reading policies of ADR-0010 apply to remote callers too.
5. **Events as a stream** (subscribe, with backpressure and drop counters), not polling.
6. **Test it with the oracle idea:** drive Sunset and the other terminals through the same command subset where they have it (kitty `@`, WezTerm CLI) and compare the observed screen.

## 5. Open questions

- Is a kitty-compatible `@kitty-cmd` subset worth it (existing tools such as editors' integrations already speak it) or is it a trap that freezes our model? Read how many third-party tools depend on it.
- MCP stdio versus the newer streamable HTTP transports for local servers: which do agent hosts actually use for local tools today? (ask's `docs/skills-and-mcp.md` and its `AskMCP` know the client side.)
- How much of the command model belongs in the core versus the app (windows and tabs live in the app; screens and zones in the core).
- Where the MCP server code lives (an `AemiMCP` promotion shared with ask, or Sunset-local first).
- Threat model for agents that may be prompt-injected through screen contents they read (the screen is untrusted input to the agent, and an agent with send-text is a confused deputy): grants should be narrow and visible.
