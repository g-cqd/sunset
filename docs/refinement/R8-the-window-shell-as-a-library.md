# R8 — The window shell as a library (roadmap 0018)

Status: **accepted by the owner 2026-11-11** (roadmap 0025, task t111). Nothing here is built.
"Shell" here is the app's window shell (sidebar, tab bar, splits, command bar), not a command shell. Input: task t111,
`docs/research/shell-extraction-2026-11-11.md`.

## The owner's answers

| Question | Answer | His note |
| --- | --- | --- |
| What it is for | Structure and tests inside Sunset first; its own repository only when a second app needs it | Could be promoted as open source if refined |
| When | Gradually: each step puts the views it writes or rewrites in the library; the rest stays in the app until its turn | |
| What goes in it | Sidebar and tab bar; the pane area (splits, drop zones, focus); the command bar; the window chrome; the settings window | |
| Configuration | The library has its own plain settings type; the app maps its configuration onto it | |
| Kinds of content | A target per kind (terminal, page, Markdown) | |
| Name and place | `SunsetShell`, in this repository | |
| Proof of the boundary | The three real kinds plug in without the shell knowing them | |

## The outcome, as one description

A library target, `SunsetShell`, in this repository, holds the window's shell: the sidebar and tab bar, the pane area with its splits, drop zones
and focus, the command bar, the window chrome and the settings window. It does not read Sunset's configuration: it has a plain settings type of
its own that the app fills. It knows no kind of content: the terminal, the page and Markdown each live in a target of their own and plug in
through the pane content protocol; that all three do so is the proof that the boundary is right. There is no big move: starting with folders,
each step puts the views it writes or rewrites into the library, and what a step does not touch stays in the app until its turn. A repository
of its own, and open source, come only if a second app needs it and the library has been refined.

Costs, as the owner asked to see them. **Safety**: the gain is here: views in a library can be unit-tested, which they cannot be in the
executable target today. **Speed and memory**: none at run time expected (same code, another module); calls across modules can lose inlining:
measured if a view on the drawing path moves, not assumed. Build time grows a little with each target. **Security**: the window chrome brings
the private-API calls with it, so `SunsetShell` depends on `SunsetPrivate` (and through it Abysm, t120); they stay named in one place.

## Said plainly

- For a while views live in two homes, the app and the library; each step's report says what moved.
- The own settings type is one more layer: each new layout key is written in the configuration, in the mapping and in the type.
- Not chosen for the library: hover previews, the + button, the close confirmation. They are drawn by or beside the sidebar, so where they
  live is asked when the step that touches them comes.
- "A target per kind": the terminal's adapter is in the app today; when it moves is asked at the first step.
- The earlier investigation proposed that the library depend on `SunsetConfig`; the owner's answer replaces that.

## Steps

| Step | What | Questions still to ask |
| --- | --- | --- |
| H-1 | With the first sidebar step of folders (t142): create `SunsetShell` and its settings type; the sidebar's views move as they are rewritten | The settings type's shape; when the terminal's target is cut |
| H-2 | A standing rule from then on: a step's new or rewritten shell views go in `SunsetShell`, a new kind in its own target; each report lists what moved | |
| H-3 | When nothing of the shell is left in the app: review the boundary with the three kinds; only then the question of a repository and open source | |
