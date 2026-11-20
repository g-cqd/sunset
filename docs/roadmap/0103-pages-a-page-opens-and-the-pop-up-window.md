---
status: in-progress
blocked-by: nothing
date: 2026-11-20
---

# 0103 — Pages a page opens, pictures and films, the page menu, and the pop-up window (notes n64, n65; tasks t130, t131)

The owner, 2026-11-20 (n64): "opening a image in another window does not work, opening the address of a media, image or video
shows a page that says it is impossible to load the page, downloading image and video from their context menu options in pages
does not work … all context menu options in pages on various elements [should] work". (n65): "popup dont work".

Asked what a page a page opens should do, the owner chose Safari's way, "with a setting specifically for that", and described
a window of its own for pop-ups (below, part B).

## A — done (diary 2026-11-20-10)

- A page a page opens (a link with a target, `window.open` after a click, a pop-up allowed when asked, WebKit's Open Image or
  Video in New Window) is `WebPlacement.opened`: a tab after its opener, **shown** while `web.showOpenedPages` is on (the
  default); a pop-up the page sized still gets a window (R1). Cmd-click and Open Link in New Tab stay behind it.
- WebKit's Open Image / Video / Frame in New Window say "New Tab", which is where they go.
- A film's or a sound's address opened in a tab plays in WebKit's media page: WebKit's "plug-in handled load" (204) is no
  longer shown as a failure.
- Download Image, Download Video and Download Linked File: WebKit hands their download over by a private method of the
  navigation delegate (`_webView:contextMenuDidCreateDownload:`, probed); Sunset's takes it into its downloads.

- Driven on screen (diary 2026-11-20-10): http addresses under "ask" load (this machine and the local network never
  upgraded; elsewhere a failure page with Load over HTTP); Open Image / Video in New Tab open; Download Video saves (WebKit's
  bytes, `saveDataToFile`); the link's Split / New Tab / New Window / Private Tab items run (WebKit's tag kept); Search the
  Web searches with Sunset's engine in Sunset.

Not done in A:
- A **picture's** address opened in a tab shows the picture here (a PNG from a local server): the owner's failing picture is
  not reproduced; an address that fails is needed.
- Look Up, Translate, Copy Link with Highlight, Share, Speech, Copy Image, Inspect Element: WebKit's own, not tried.
- Open Link in New Window and Private Tab: run (their tag kept), not pictured.

## B — the pop-up window (not started)

The owner's words: "a different variant of window chrome for popups that would just be enclosed in the slight margin window,
corner radii on all corner and just a little space above the content to have the traffic lights (on the side the sidebar is)
and the other side a button with 'open in <current space>' ^ with selector for the space to open/move the popup as a standard
tab there. it should not exist as a standard tab until then, and it should not show the sidebar at all".

- A window kind of its own for a page opened as a pop-up (sized by the page; which others go there is to be decided with the
  owner): the window's margin around one card, every corner round, a strip above it with the lights on the sidebar's side and,
  on the other, "Open in ‹Space›" with a menu of the Spaces.
- The page is in no Space's tabs until moved; moving makes it a tab there and closes the window.
- No sidebar, no tab bar.

Needs: the window's look seen on screen; what happens to it when its opener closes; whether a session keeps it.
