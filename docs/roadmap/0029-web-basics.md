---
status: done (2026-11-13; steps 1 to 8)
blocked-by: nothing
date: 2026-11-13
---

# 0029 — Web basics that pages rely on

The owner's note n72 (2026-11-13): better web features and a more complete implementation first. An audit of the web pane the same
day found basics missing that pages rely on. The owner's order: this batch, then Markdown (0023), then web beyond the first pane
(0022). Task t250.

## Steps

| Step | What | State |
| --- | --- | --- |
| 1 | JavaScript dialogs: `alert`, `confirm`, `prompt` as a panel on the page; a page that keeps asking can be silenced | done 65c00c7; seen: confirm, prompt (typed and cancelled), three alerts silenced at the second |
| 2 | File upload: `<input type=file>` opens the system's panel (one or several files, folders when the page asks) | done; seen: the sheet opens and cancels; a file actually chosen not seen |
| 3 | Video and element fullscreen; pinch to zoom | done (a test reads both); not seen on screen (fullscreen takes the screen; a pinch cannot be posted) |
| 4 | Print (File > Print, Cmd-P) | done; seen: the system's sheet with the page's preview |
| 5 | A page's process that ends: our failure page with Reload | done; seen: the process killed, "This page stopped", Try Again loads it |
| 6 | The address of the link under the pointer, at the bottom of the page | done 943dbc1; seen with the pointer's event sent by the test page (the driver cannot move the pointer over a background window) |
| 7 | Sound: a mark on the tab of a page that plays, and Mute | done 5a15917; seen: a tone plays, the speaker shows, History > Mute Page slashes it. Private API (`SunsetPrivate.WebAudio`) |
| 8 | A password asked by a server (HTTP Basic and Digest): a panel on the page | done; seen against `auth_server.py`: a wrong password is said, the right one signs in. Kept for the run only, not in the keychain |

Policy (white paper §9): a page is an untrusted program. Its dialogs are text only, in the page's own pane, named by its host; it
cannot open more than one at a time, and after the second in a row the panel offers to silence it until the page is left. A link's
address under the pointer is shown as text, cut to a length. Nothing a page says is run or styled.

## Not done

Not seen on screen: fullscreen and pinch (step 3), a file actually chosen (step 2), a real pointer over a link (step 6), the dialogs
in the light scheme. Not built, and not in this batch: the question a page asks when it is left (`beforeunload`), passwords and
passkeys autofill (study t163) and saving a server's password in the keychain, a reader view, translation, picture in picture
controls of our own, page previews in the sidebar (t139), site icons kept in the session.
