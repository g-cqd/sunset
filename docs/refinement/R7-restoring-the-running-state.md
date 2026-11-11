# R7 — Restoring the running state (roadmap 0018)

Status: **accepted by the owner 2026-11-11** (roadmap 0024, tasks t122, t174-t178). Nothing here is built.
Input: note n46, task t122. As built today: tabs, splits, each pane's directory, names and icons come back over new shells (`tabs.restore`).

## The owner's answers

| Question | Answer | His note |
| --- | --- | --- |
| Programs | Screens first | A study of how to keep processes, later, could be interesting |
| If a keeper process comes | It holds the whole terminal: parser, screen, scrollback | |
| What is kept of a screen | The screen and all its scrollback | Behind a setting |
| On disk | Encrypted, the key in the Keychain | Behind a setting |
| When it is written | At quit and when a window closes | |
| A restored terminal | The old text, a marker line, then a new shell | |
| A command that was running | Nothing first | Alternatives could be studied |
| At launch | One setting, three levels: always restore, ask each time, never; the dialog can remember | |
| After a crash | Always ask | |
| With a keeper, what Quit means | A setting chooses (keep or end); the other is the alternate menu entry | |
| Never saved | Private pages | |
| Pages beyond address, history and scroll | Study what more WebKit can give, with the sleeping study (t134) | |
| When | After everything else decided so far | |

## The outcome, as one description

**First, screens.** When the app quits or a window closes, each terminal's screen is written to disk, with its scrollback when the setting says
so, encrypted with a key in the Keychain when the setting says so. At the next launch one setting decides: restore, ask, or do not; after a crash
the app always asks. A restored terminal shows its old text, a marker line saying when the session ended, and a new shell under it. Nothing is run
again. Private pages are never saved.

**Later, a study of keeping programs alive**: a separate process that holds the terminals while the app is away. The owner's preference, recorded
for it: the keeper holds the whole terminal (parser, screen, scrollback) and the app is a window onto it; what Quit means is then a setting. The
study is read back before any decision. A second small study, also later: what could be offered for a command that was running.

Pages: R1's level stands (address, history, scroll); what more WebKit can give is added to the sleeping study.

Costs, as the owner asked to see them. **Security**: saved screens are terminal text on disk, secrets included; encryption keeps other programs
out as long as the Keychain does, and with it off they are files only the owner's account reads, as shell history is; files are removed when their
tab is closed. **Memory and disk**: all scrollback of many panes can be large: sizes are measured and reported at the step, and a limit is
asked there. **Speed**: writing at quit lengthens quitting in proportion; it is done off the main thread and measured; launch reads only what
is shown. **Safety**: written atomically; a file that fails to read or decrypt gives a new shell and says so, never a broken screen.

## Said plainly

- Saving only at quit means **a crash or a power loss restores the state of the last clean quit**, not of the moment before the crash. The owner
  chose this over a timer; "always ask after a crash" then offers that older state.
- "Behind a setting" twice: I read that scrollback saving and encryption are each a switch. Their defaults are asked at the step.
- Encryption rests on the study t135 (after the web milestone); this work comes after it by the owner's order, so it can use what was decided.
- The alternate screen (a full-screen program at quit) was not excluded: what is saved for it is asked at the step.
- A keeper holding the whole terminal makes every frame cross between two processes; unmeasured, and the study's first question.

## Steps (each begins with its own questions)

| Step | What | Questions still to ask |
| --- | --- | --- |
| S-1 | The screen and scrollback as a file: format, atomic write at quit and window close, removal with the tab; sizes and times measured | Defaults of the two switches; a size limit; the alternate screen |
| S-2 | Restoring: the old text, the marker line, a new shell; failure gives a plain new shell | The marker's wording and look |
| S-3 | The launch setting (three levels), the dialog with "remember", always asking after a crash | How a crash is known |
| S-4 | Encryption with the Keychain key, as a switch (after t135) | |
| Study | Keeping programs alive: the keeper (whole terminal in it), launchd, security, cost per frame, what Quit means; read back | |
| Study | A command that was running: what could be offered | |
