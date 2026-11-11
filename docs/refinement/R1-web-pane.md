# R1 — The web pane (roadmap 0018)

Status: **round 1 answered (2026-11-11); round 2 open.** Nothing here is built. The first web pane (e5bd1e9, aa1c900) was removed on the owner's
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
