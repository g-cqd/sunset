---
status: sessions R1 to R11 done and accepted 2026-11-11; one asked for since is still to hold: the document store (t172)
blocked-by: nothing (the owner's time)
date: 2026-11-11
---

# 0018 — Refinement phase: every coming topic is decided with the owner before it is built

Asked by the owner on 2026-11-11, after a web pane was built on eleven design decisions he had not seen (white paper §10). Until a topic has been
through its session here, no code is written for it.

## How a session goes

1. The agent sends the topic's questions, all of them, each with its alternatives, what each costs and excludes, and what is already in the tree
   that bears on it. A recommendation, when there is one, is marked as the agent's and comes after the alternatives, not instead of them.
   Every alternative says what it costs in **speed, efficiency, memory, safety and security**: the owner holds these as important as the feature
   itself (2026-11-11), so an alternative without those costs stated is not ready to be chosen from.
2. The owner answers, changes the questions, adds his own. More rounds as needed.
3. The outcome is written down (an ADR for a decision, a design note for a shape) and read back to the owner.
4. Only then are tasks made from it, in the order the owner gives, and the roadmap file of the topic is written or corrected.

A session does not start the next one. Nothing is built during the phase except what a session's outcome says, and defects in what exists.

## Sessions (order proposed by the agent, to be set by the owner)

| # | Topic | What is to be decided | Bears on |
| --- | --- | --- | --- |
| R1 (done 2026-11-11: `docs/refinement/R1-web-pane.md`, roadmap 0019) | Web pane as built | Keep, change or revert it; the eleven decisions taken without the owner (engine per pane, the address row, what typing means and the search engine, the agent string, the data store, new-window links, what is saved, the shortcut, the tab's look, closing, inspection) | t114, n42 |
| R2 (done 2026-11-11: `docs/refinement/R2-panes-that-are-not-terminals.md`) | Panes that are not terminals, as built | The protocol's shape, the note pane (keep as a feature, keep hidden as a test kind, remove), the placeholder for unknown kinds, how a new pane of a kind is asked for (menus, command bar) | t109 done, t111 |
| R3 (done 2026-11-11: `docs/refinement/R3-folders-names-icons.md`, roadmap 0020) | Sidebar folders, pinning, names and icons | The tree (depth, what a folder holds, splits inside folders), colours, how a folder is made and filled, drag rules, what a collapsed folder shows; what is left of renaming (inline editing, a symbol picker) | t112, t113, n40, n41 |
| R4 (done 2026-11-11: `docs/refinement/R4-spaces-and-profiles.md`, roadmap 0021) | Spaces and profiles | What a Space owns (tabs, folders, tint, icon, directory, web data), what a profile is above it (n45 names profiles > spaces > website), switching, where it shows, what is shared, persistence and migration | t110, n45 |
| R5 (done 2026-11-11: `docs/refinement/R5-web-beyond-the-first-pane.md`, roadmap 0022) | Web, beyond the first pane | The engine: the system's, or the latest WebKit (and what the owner means by it: a bundled build, Technology Preview, something else); agent presets and making WebKit pass for another browser, per site / Space / profile; content blocking; extensions; the order of all these | t119, t121, n42, n45 |
| R6 (done 2026-11-11: `docs/refinement/R6-markdown.md`, roadmap 0023) | Markdown pane | Reading, editing or both; which parts of MarkdownLook move into its library and who moves them; files on disk or notes in the session; how it meets the note pane | t115, n43 |
| R7 (done 2026-11-11: `docs/refinement/R7-restoring-the-running-state.md`, roadmap 0024) | Restoring the running state | What "exact state" covers; a session daemon that keeps programs alive, or screens restored over new shells; what is asked at launch and what is a setting | t122, n46 |
| R8 (done 2026-11-11: `docs/refinement/R8-the-window-shell-as-a-library.md`, roadmap 0025) | The window shell as a library | Whether and when; its boundary; its name and repository; what the app keeps | t111 |
| R9 (done 2026-11-11: `docs/refinement/R9-terminal-open-ends-and-notes.md`, roadmap 0026) | The terminal's open ends | OSC 21 and 66, bash shell integration, the resize behaviour of n29, confirming a window's close (the agent's proposition), font settings (n2), the feature survey (n18), remote control (n1), and when performance work resumes | t58, t108, t94, t118, t55, t77, t40, t100 |
| R10 (done 2026-11-11: the list is cut from 64 open tasks to those that stand; `docs/STATE.md` rewritten; eight leftovers kept as candidates for R9, task t141) | The task list and the roadmap files | Which old tasks are closed, merged or kept (the list has tasks from before the app existed); bringing `docs/STATE.md` and the roadmap files up to what exists | all |
| R11 (added by the owner in R6; done 2026-11-11: `docs/refinement/R11-commands-intents-and-remote-control.md`, roadmap 0027) | Commands, App Intents and the command bar | Every action declared once and run by menus, keys, the command bar, App Intents, later remote control; what the system may run without asking; the command bar running actions with no prefix, by word matches, ranked, tolerant of errors | t186-t194 |

## Done when

Each session has its written outcome, accepted by the owner, and the tasks that follow from it exist in his order.
