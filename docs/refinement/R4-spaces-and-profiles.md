# R4 — Spaces and profiles (roadmap 0018)

Status: **accepted by the owner 2026-11-11** (roadmap 0021, tasks t110, t147-t153). Nothing here is built.
Research asked for during the session: `docs/research/tab-sleeping-in-browsers-2026-11-11.md`.

## The owner's answers

| Question | Answer | His note |
| --- | --- | --- |
| What a Space owns | Its tabs and folders, its own kept section, a name and an icon, a look | A directory and a shell environment: a much later phase |
| What a profile is | A web identity: one WebKit data store (cookies, logins, history, permissions, user-agent rules). A Space has one profile; several Spaces may share it | Terminal settings per profile or Space: a much later phase |
| The sidebar's sections | Three, top to bottom: **Pinned** (the profile's, the same in each of its Spaces), **Favorites** (the Space's: pages, terminals, folders; entries stay open or not), **Tabs** (the Space's, made on the fly, live until closed, restored at relaunch per the restoration settings) | In Pinned and Favorites Cmd-W unloads and keeps the entry; removing is explicit |
| Pinned, its form | A grid of icons; pages and terminals, no folders | A split set of tabs is one pinned entry |
| Folders | Only in Favorites | They should support WebKit's native favourites; importing other browsers' favourites, which can be delayed |
| The button on a kept row | Favorites: a minus while open, which unloads; once unloaded the entry is no longer the selected one, so a collapsed folder that showed it shows only its row; hovering an unloaded entry offers an x that deletes it. Pinned: menu actions only | |
| Spaces and windows | App-wide; the same Space can show in several windows. A tab's content is live in one window; the others show its last picture; the active window takes control and rendering, whatever the kind | |
| A Space not shown | Its terminals run. Pages go to sleep and unload (below) | |
| Which pages sleep | Any page not on screen, in the Space shown too | |
| Delays | Three settings: sleep after (default 15 min), unload after (default 12 h), unload under memory pressure, longest idle first (default on) | Fine settings, sensible defaults, after looking at Chrome, Safari, Firefox |
| Never unloaded by the delay | Playing audio or video; unsent form text; pinned entries that are open; in a call or using camera, microphone, screen; driven by an agent or a terminal; marked "keep awake" by the person | |
| The cue | A moon badge by the icon when asleep; a dimmed icon when unloaded; the same dimming for a terminal that is not running | A cue for loaded, going to sleep, unloaded |
| The sleeping study (t134) | After the web milestone, before Spaces | |
| Switching | Two-finger swipe on the sidebar; a row of Space icons; keys; the command bar; a Spaces menu in the menu bar | Keys configurable |
| The icons row | Bottom of the sidebar, beside the + button | With no sidebar: a header with a menu, in the tab bar |
| With no sidebar | A small button in the tab bar | The profile and the Space in one button and menu |
| The look | Tint, colour scheme and material can differ by Space | Not important now: anticipated, optional, by default all Spaces look the same |
| A Space's directory | Not now. When it comes: always for a new tab; a split inherits its neighbour's | |
| Activity in a Space not shown | A mark on its icon, and the system notification names the Space; clicking it goes to the Space and the tab | |
| Moving to another Space | Context menu Move to Space (a selection too); dragging to the sidebar's edge slides to the next Space | |
| Deleting a Space that holds things | Asks: close everything, or move it to another Space | |
| With one Space | Nothing shows; New Space is in the menu and the + menu. Sessions saved until now become one Space | |
| Links from outside or from a terminal | The Space shown, with its profile; rules by site are decided in R5 | |
| Changing a Space's profile with pages open | The pages reload in the new profile, after a confirmation | |
| Deleting a profile | Asks: also delete its Spaces, or reassign them; its website data is erased | |
| Where profiles are managed | Settings (a Profiles section), the Space's own editor, the Spaces menu | |
| Order | Folders, web, Spaces, profiles | |

## The outcome, as one description

A **profile** is a web identity. A **Space** belongs to one profile and owns a name, an icon, its Favorites and its Tabs. Spaces are app-wide: any
window can show any Space, and two windows can show the same one.

The sidebar has three sections. **Pinned**, at the top, is a grid of icons that belongs to the profile: pages, terminals, or a split set as one
entry; it is the same in every Space of that profile and is acted on through its menu. **Favorites** belongs to the Space and is the only place
folders live (four levels, as R3). **Tabs** are what is opened on the fly. What is in Pinned or Favorites is kept: Cmd-W, or the minus on a
Favorites row, unloads it (a page is released, a terminal's shell is stopped, with the confirmation when something runs) and the entry stays,
dimmed and no longer selected; an unloaded Favorites entry offers an x on hover that deletes it. Closing a tab in Tabs removes it.

When a Space shows in two windows, each tab is live in one of them: the window being used takes the tab's control and rendering, and the other
shows the tab's last picture.

Pages that are not on screen sleep after 15 minutes and unload after 12 hours, and under memory pressure the longest idle unload first; each of
the three is a setting. Pages that play, hold unsent text, are in a call or capturing, are pinned and open, are driven by an agent or a terminal,
or are marked keep-awake are left alone. A sleeping page has a moon by its icon; anything unloaded, page or terminal, has a dimmed icon. What
WebKit allows for the sleeping stage is not known until the study (t134), which is done after the web milestone and before Spaces.

The Space is changed by a two-finger swipe on the sidebar, a row of icons at the bottom beside the + button, configurable keys, the command bar
and a Spaces menu; with no sidebar, by one button in the tab bar that names the profile and the Space. Until a second Space exists none of this
shows. Activity in a Space not shown marks its icon, and its notification names the Space. Tabs and folders move by Move to Space or by dragging
to the sidebar's edge. Deleting a Space asks whether to close what it holds or move it; deleting a profile asks the same of its Spaces and erases
its website data; changing a Space's profile reloads its pages after a confirmation.

Costs, as the owner asked to see them. **Memory**: a parked Space's terminals stay (their programs run); pages are bounded by the sleep and unload
settings; an entry that is not open is a few strings; the picture shown in a second window is one image per tab shown there, dropped when that
window leaves the tab; each profile in use adds WebKit's own storage and network processes (to be measured, not known). **Speed**: switching
Space swaps one tree for another and redraws; waking a sleeping page is immediate if WebKit can suspend, a page load if not. **Safety**: one live
view per tab, so keys go to one place; an unload never takes a page with unsent text, as far as that can be detected (the page's own signal and
edited fields: not perfect, said plainly). **Security**: sites in one profile cannot read another's cookies or storage; Pinned never crosses
profiles; a link opens in the Space shown, so a work link clicked in a personal Space opens with the personal identity until R5's rules exist.

## What this changes in R3 (accepted earlier the same day)

- R3's "pinned section" is **Favorites** (per Space). **Pinned** is now the profile's grid at the top.
- Folders live **only in Favorites**. This replaces R3's "a folder need not be pinned": grouping tabs into a folder moves them into Favorites.
  A folder there still lives until removed by hand, even empty.
- "Unpin" becomes moving an entry out of Favorites into Tabs; "Delete" stays, and is the x on an unloaded entry.
- Before Spaces and profiles exist (folders come first), there is one Space and one profile, unnamed and not shown: Favorites and Tabs are the
  window's, and Pinned waits for profiles unless the owner wants it earlier.

## Left out, said plainly

- **WebKit's native favourites.** I do not know of a bookmarks API in WebKit; Safari keeps its own file, which the system protects. Unverified:
  it needs a study before it can be promised. Importing from other browsers is delayed by the owner's word.
- A directory, a shell environment and terminal settings per Space or profile: a much later phase.
- The look per Space: the format leaves room; no editor until asked.
- Rules sending a site to a Space, and per-site settings: R5.
- Whether "pinned entries that are open are never unloaded" now means Pinned only or Favorites too: asked at the sleeping step.

## Steps (each begins with its own questions)

| Step | What | Questions still to ask |
| --- | --- | --- |
| S-a | The model in `SunsetPane`: Spaces, their sections, the session file; a session saved before becomes one Space | Ids; whether the order of Spaces is per window |
| S-b | Switching: the icons row, the swipe, keys, the command bar, the Spaces menu; the button in the tab bar; nothing with one Space | Default keys; how the swipe and scrolling the list are told apart |
| S-c | The Space's editor (name, icon), New Space, Move to Space, drag to the edge, deleting | What a new Space starts with |
| S-d | The same Space in several windows: one live view, the last picture elsewhere | What the picture looks like (dimmed, a label); what a click on it does |
| S-e | Activity marks and notifications naming the Space | |
| S-f | Sleeping and unloading: the three settings, the exceptions, keep awake, the cue (after study t134) | What WebKit allows; Pinned only or Favorites too; where keep-awake is set |
| P-a | Profiles: a data store each, the Settings section, the picker in the Space's editor, the Spaces menu; changing and deleting | The first profile's name; what a private page (R1 step h) is beside a profile |
| P-b | Pinned: the profile's grid (pages, terminals, a split set), its menu | Tile size and count; how something is pinned |
