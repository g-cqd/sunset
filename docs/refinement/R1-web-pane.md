# R1 — The web pane (roadmap 0018)

Status: **accepted by the owner on 2026-11-11.** Nothing here is built. The steps are roadmap 0019 and tasks t125-t136. The first web pane (e5bd1e9, aa1c900) was removed on the owner's
answer "revert, rebuild"; a saved session that has a `web` pane shows it as a placeholder and keeps it.

## Round 1: the owner's answers

| Question | Answer | His note |
| --- | --- | --- |
| What it is for | Local previews; general browsing; driven by agents | |
| The pane that was built | Revert, rebuild from this session's outcome | |
| A page's life | Made when shown, and sleeps when not looked at | Investigate the official and upstream WebKit APIs that control sleeping |
| Where the address is | Configurable | A general bar at the top or the bottom (configurable) that can collapse and appear when the pointer reaches its area; or a row per tab; or a compact address bar at the top or bottom of the sidebar |
| Text that is not an address | Searched, with the engine a setting | Customisable: new engines can be set up, with their prediction and suggestion addresses |
| A host with no scheme | https first | A setting loosens it to fall back to http; local addresses stay reachable |
| What a page sees as the browser | Safari, read from the system | (presets and passing for other browsers: R5) |
| Cookies and site data | One persistent store | Perhaps encrypted: to be studied and refined, as a feature the user turns on (Aemi's Argon work, or other encryption) |
| A link that asks for a new window | A new window | Sunset's context menu offers to open in a split: both directions in the menu, and/or a default direction in the settings, and/or a choice made on the spot |
| What is saved of a page | Address, history and scroll | |
| How a page is opened | Menu item; shortcut; the command bar; Cmd-click on a link in a terminal | |
| What a tab shows | As built (globe, title, host, progress), as a setting | Favicons as a choice; his preference: a square with the initial of the site's title or host |
| Closing | The page may object | Quitting Sunset is held back by an active terminal process or a page that objects; and a setting to be asked before quitting whatever the state, with a way to remember or turn off |
| Inspector | Own menu item too | A developer setting turns inspector access on or off |

## Rounds 2 and 3: the owner's answers

| Question | Answer |
| --- | --- |
| In the first web milestone | Find in page, zoom, downloads, history, permissions, private pages. Not passwords or passkeys |
| Pages driven by agents | After the first milestone, with remote control, in its own session |
| Default place of the address | The compact field in the sidebar |
| Placements built in the first milestone | All three (window bar top/bottom that collapses, a row per pane, the sidebar field) |
| With a terminal focused | The address bar hides |
| With the sidebar off or hidden | The window bar takes over |
| Engine suggestions | On by default |
| Default search engine | Google |
| Straight to http, never tried over https | localhost and loopback, `.local` names, private ranges, single-label names |
| One word typed alone | Searched, unless marked as a host by a port or a slash (`nas:8080`, `nas/`) |
| A window a page asks for | Only after a click; one that has a size is a small window of that size, with no sidebar or tab bar, closed when the page closes it |
| The link menu | Open in Split Right, Open in Split Down, Open in New Tab, Open in New Window, Copy Link |
| Cmd-click on a link in a terminal | Opens in a split beside the terminal; a setting keeps the default browser |
| The tab's picture | A setting (globe, favicon, initial in a square); default: the initial of the page's title |
| Quitting | One setting, three levels: never ask / ask when something would be lost (default) / always ask; the dialog's "do not ask again" sets it to never |
| Closing a window | Not covered: quitting only |
| The two studies (sleeping, encrypting the store) | Both after the first milestone: it has no sleep and a plain store |
| Inspector access (developer setting) | On by default |
| The shortcut for a new page | Configurable |
| How it is cut | In steps, each with its own questions before it is built, each seen working before the next |

## The outcome, as one description

A web pane is a kind of pane content on the system's WebKit, naming itself as the installed Safari does. A page is made when its tab is first shown
and, in this milestone, lives until the tab closes. All pages share one persistent store. A page's address, back and forward history and scroll
position are saved with the session.

The address is typed in one of three places, by a setting: a compact field in the sidebar (the default), a bar for the window at its top or bottom
that collapses and comes back when the pointer reaches it, or a row in each pane. The bar hides while a terminal has the keyboard, and the window bar
stands in for the sidebar field while the sidebar is not shown. What is typed is an address (https first; http at once for this machine and the
local network; a setting allows falling back to http elsewhere), or words to search with the engine chosen in the settings (Google at first), where
engines can be added with their search and suggestion addresses, and suggestions are on.

A page is opened from the Panes menu, by a shortcut the user can set, from the command bar, and by Cmd-click on a link in a terminal (in a split
beside it). A link's menu offers the two splits, a new tab, a new window and copying it. A page gets a new window only after a click.

A tab shows the title, the host and the loading progress, with the title's initial in a square as its picture unless the setting says globe or
favicon. Closing a page shows the page's own objection when it has one. Quitting asks when a terminal command runs or a page objects, by the
three-level setting. The Web Inspector has its own menu item, behind a developer setting that is on.

## Steps (each begins with its own questions)

| Step | What | Questions still to ask |
| --- | --- | --- |
| a | The pane: engine, restore with history and scroll, the new-window rules, the link menu, the inspector, the tab's look, the page's objection on close | The default shortcut and what "configurable" covers (Sunset has no shortcut settings today: only this one, or all menu shortcuts); where a new tab from a link goes; the wording of the placeholder for a page that fails to load |
| b | The three address placements and their setting | The window bar's content and height, how it collapses, what the sidebar field looks like when collapsed, back/forward/reload in each placement |
| c | Search engines and suggestions | The settings' shape, the engines that come built in, how suggestions are shown and mixed with history |
| d | Find in page, zoom | Where the find field is; zoom per page or per site, remembered or not |
| e | History | What is kept and for how long, where, how it is cleared, how it is searched |
| f | Downloads | Where files go, what shows progress, what is asked before saving |
| g | Permissions | Camera, microphone, location, notifications: asked how, remembered where, reviewed where |
| h | Private pages | What marks one, its store, what is never saved |
| q | The quit confirmation | The dialog's wording, what counts as "would be lost" for each kind of pane; it touches terminals, so it is its own step |

## After the milestone, each with its own session

- Sleeping pages: study the official and upstream WebKit controls first (owner's note).
- Encrypting the store, as a feature the user turns on: study first (Aemi's Argon work or other encryption; what WebKit lets an app do with its
  store at all).
- Pages driven by agents (with remote control).
- R5: the latest WebKit, agent presets and passing for another browser, content blocking, extensions. Passwords and passkeys are in no milestone yet.

## Step a, its questions answered (2026-11-11)

| Question | Answer | His note |
| --- | --- | --- |
| The shortcut | Cmd-T makes a tab of the same kind as the focused one; Shift-Cmd-T opens a choice of kinds; Cmd-L is for the address | "Usual command T to create a tab of the same kind as the one focused right now, with maybe command shift T to open a dialog for selection" |
| A link's new tab | Right after the page's tab, not shown | |
| A failed load | A plain page of ours (what failed, the system's reason, the address, Try Again); certificate errors offer Visit Anyway after a warning | |
| Named as Safari | Decided at the step | "Make it appear as Safari by default" |

## Step b: the owner's answers (2026-11-11)

| Question | Answer |
| --- | --- |
| The sidebar field's place | At the top, under the window buttons |
| What a field shows when not typed in | The host; clicking shows the whole address selected |
| Back, forward, reload buttons | In the window bar only (reload turning into Stop while loading); none in the sidebar field or the pane row |
| Keys | Cmd-[ back, Cmd-] forward, Cmd-R reload, Shift-Cmd-R reload without the cache, in a History menu with Back, Forward, Reload, Stop |
| The sidebar field while a terminal is focused | Hidden, the list closes up |
| How the window bar collapses | Hidden; shown when the pointer reaches its edge or on Cmd-L; hidden again after the pointer leaves it |
| The window bar's content | Back, forward, reload/stop, the address, a progress line |
| The row per pane | Not the default; when chosen, on every web pane |
| Loading shown | A thin line along the field's bottom edge, and reload turning into Stop |
| Where the placement is chosen | Settings only |
| Cmd-L | Stays the command bar, which takes addresses too: a "Go to <address>" row loads in the focused page, or in a new page tab when a terminal is focused. The window bar is then brought by the pointer only |
| Rename Tab's Shift-Cmd-R | Removed (menu and double-click only); Shift-Cmd-R reloads without the cache |
