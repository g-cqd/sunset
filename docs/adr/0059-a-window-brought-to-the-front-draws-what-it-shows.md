---
status: accepted
supersedes-in-part: 0045 (bringing a window to the front)
date: 2026-11-17
---

# 0059 — A window of a Space brought to the front draws what it shows, and leaves the other its picture

The owner, 2026-11-17 (roadmap 0035 J): "Tab focusing for a space with multiple window does not rerender correctly in the
new window when switching to it"; what he saw: "white or black page, and the other page does not even show the last
snapshot, it just shows the notice about the clicking to make it come back". ADR-0045 had his earlier answer, "bringing a
window to the front takes nothing". Asked which he wants now: **both**.

## What was wrong

- A window brought to the front showed the picture of a tab live in the other window, and waited for a click.
- A page has no picture: only a terminal has one (its last surface). The window showed an empty pane, white or black by
  the appearance, under the notice.

## Decision

1. **The window brought to the front** (it becomes the key window) **draws what it shows**: the tab, or the kept entry,
   live in another window is taken (`TabsModel.cameToFront`), as a click on it would. A window that already draws it, or
   shows nothing, takes nothing.
2. **The window it leaves keeps a picture**: as a tab or a kept entry moves to another window its contents are asked for a
   picture (`PaneContent.takePicture`). A page takes a snapshot of itself (`WKWebView.takeSnapshot`); a terminal keeps
   using its last surface. The notice stays over the picture; a click on it takes the tab back.

## Not done

- Not seen on screen (no accessibility for the terminal the agent runs in, 2026-11-17). The model is tested
  (`SpaceWindowFrontTests`); the snapshot and its drawing are not.
- A picture is taken as the tab leaves; it is not refreshed while the other window draws the page.
