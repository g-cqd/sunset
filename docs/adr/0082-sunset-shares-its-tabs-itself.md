---
status: accepted
date: 2026-11-18
---

# 0082 — Sunset shares its own tabs itself; macOS's picker for screens, windows and apps

The owner's note n49 (2026-11-18): a page asking to share the screen may share any open tab of Sunset, of any kind, other
profiles' by a setting, natively as far as can be, without losing screens, desktops and windows. macOS's picker
(ScreenCaptureKit, which WebKit uses) sees windows, not tabs. The owner first chose a window of its own for the tab chosen,
then: "capturing ourselves would be better integrated".

## Evidence (release, `Scripts/probes/share-tab-frames.swift`, 1920×1080, 120 frames, this Mac)

| Step | p50 | p90 | p99 |
|---|---|---|---|
| A page's snapshot (`takeSnapshot`, in a window off screen) | 4.1–4.3 ms | 4.6–5.2 ms | 5.0–8.5 ms |
| JPEG, quality 0.6 (ImageIO), ~138 KB a frame | 11.3–11.5 ms | 11.7–12.3 ms | 11.9–21.3 ms |
| Into the page (base64 through `callAsyncJavaScript`, decoded, drawn on a canvas) | 15.9–16.5 ms | 17.8–18.2 ms | 21.5–25.0 ms |
| The same through a URL scheme handler the page fetches | 18.1 ms | 22.2 ms | 25.6 ms |
| Pipelined (the next snapshot while the last is delivered): snapshot to drawn | 51.2 ms | 66.2 ms | 67.0 ms |

Frames: 29.6–31.0 fps one after another, 37.0 fps pipelined. The canvas's `captureStream` track is taken by an
`RTCPeerConnection` (a video offer made), and a wrapped `getDisplayMedia` hands it to the page.

## Decision

1. When a page asks to share, Sunset shows its own list: every open tab (terminals, pages, documents), by Space; other
   profiles' only with `web.shareOtherProfiles` (off). A row "Screen, Window or App…" gives the page WebKit's own
   `getDisplayMedia`, and macOS's picker.
2. A tab chosen reaches the page as a stream Sunset makes: a script in the page's world wraps `getDisplayMedia` and returns a
   canvas's `captureStream`; Sunset sends the tab's frames (JPEG, base64, the route measured fastest), pipelined, at most
   30 fps, the size the page asks or the tab's.
3. Policy (white paper §9): a page receives another tab's pixels only after the person's choice, each time; the tab shared
   shows it is shared; sharing stops when either tab closes, the shared tab's page navigates to another site, or the person
   stops it from either tab. A page's own wrapper cannot be called by the page to pick a tab: the choice is Sunset's sheet.
4. A tab not on screen is drawn off screen to be snapshot (in a window off screen, as in the probe).

## Consequences

- A site that inspects where a stream comes from may refuse a canvas's; "Screen, Window or App…" stays for it.
- Encoding is most of the cost: VideoToolbox's hardware JPEG, or a smaller size, is the first thing to try if frames drop.
