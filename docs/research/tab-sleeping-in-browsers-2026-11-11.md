# How browsers put background tabs to sleep (asked by the owner in R4, 2026-11-11)

Read on 2026-11-11 from each vendor's own pages. Tags: **[read]** quoted or paraphrased from the page named; **[unverified]** from what I know,
not found on a page today. No browser was run or measured.

## Chrome: Memory Saver [read: support.google.com/chrome/answer/12929150; developer.chrome.com/docs/web-platform/page-lifecycle-api]

- One switch, and three levels with **no stated durations**: Moderate ("inactive after a longer period"), Balanced (recommended, "an optimal
  period"), Maximum ("a shorter period"). An inactive tab reloads when it is selected.
- Not deactivated: active audio or video (playback or calls), screen share, page notifications, active downloads, partially filled forms, pinned
  tabs, connected devices (USB or Bluetooth).
- A list "Always keep these sites active", by address pattern.
- A cue: with "Inactive tabs appearance" on, the tab's icon is drawn inside a ring. Memory use can be shown in the tab's hover card.
- Two states underneath (Page Lifecycle): *frozen* (kept in memory, not run) and *discarded* (unloaded). Chrome says it discards conservatively:
  pages seen playing audio, using WebRTC, updating the title or favicon, showing alerts or sending notifications while hidden are not discarded
  "unless under extreme resource constraints".

## Edge: sleeping tabs, then discard [read: learn.microsoft.com, policies SleepingTabsTimeout, AutoDiscardSleepingTabsEnabled]

- Sleep after a chosen time in the background: 30 s, 5 min, **15 min (the default)**, 30 min, 1 h, 2 h, 3 h, 6 h, 12 h. With the energy saver
  the shorter of that and 5 min (maximum savings) or 30 min (15 min under 6 GB of memory) applies.
- A list of sites that never sleep (policy SleepingTabsBlockedForUrls).
- Discard is a second stage, on by default: a background tab is discarded after it stayed in the background through three browsing sessions (a
  session starts when the browser is used after more than 12 hours).
- [unverified] sleeping tabs are drawn faded.

## Firefox: only under memory pressure [read: gecko-dev browser/components/tabunloader/docs/index.rst; hacks.mozilla.org, Tab unloading in Firefox 93]

- No timer. When the system's available memory is low, tabs are unloaded in least-recently-used order. Never the foreground tab. Tabs playing
  media, using Picture-in-Picture or WebRTC are excluded (the 2021 article says weighted against); pinned tabs are less likely.
- With more than about eleven tabs it also estimates each tab's memory and prefers unloading the larger ones.
- One preference turns it off; `about:unloads` shows the order and unloads by hand.

## Safari [unverified]

I found no Apple page describing a setting or a timer. What I know, unchecked: Safari on the Mac has no user setting for this; it reloads a tab
that was using significant memory and says so in a banner. What WebKit itself offers an app (suspending, discarding, the official and upstream
controls) is the subject of task t134 and is not known yet.

## What they share

1. Two stages exist in Chrome and Edge: stopped but kept (instant return), then unloaded (reload on return). This matches the three states the
   owner named: loaded, sleeping, unloaded.
2. The exceptions are nearly the same everywhere: sound or video, calls and capture, pinned, unsent forms, downloads, devices.
3. A per-site "never" list (Chrome, Edge).
4. A timer (Edge: 15 min by default; Chrome: unnamed levels) and memory pressure (Firefox only by that) are both in use; no one unloads on a
   short timer by default: Edge's discard takes days.
5. A cue on the tab (ring, fade).
