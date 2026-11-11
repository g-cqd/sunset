# R5 — Web, beyond the first pane (roadmap 0018)

Status: **two rounds answered (2026-11-11); the outcome below is to be read and accepted by the owner.** Nothing here is built.
Input: notes n42, n45; `docs/research/search-browser-review-2026-11-11.md`; R1 and R4.

## The owner's answers

| Question | Answer | His note |
| --- | --- | --- |
| The engine | Our own WebKit build, shipped with the app, beside the system's | "Remote" in n42 meant WebKit's repository: build on macOS's WebKit or on a latest build of ours |
| How the two are offered | Two builds of the app | Switching from one to the other without hassle, with download and reload handled by the app, can be studied later |
| Which WebKit ours follows | The tip of main, on a schedule | |
| Patches | WebKit as it is first; a patch only when a decided feature cannot be done otherwise, each put to him with its upkeep | |
| Security rule | A release cadence we hold | Distribution is not handled yet: the project is local for now |
| Delivery | Inside the app bundle now, a downloaded component later | |
| Where it is built | Decided after the spike | His machine for now, CI possibly later |
| When | Last of all in R5 | |
| What the own engine may lose | Read back to him, then he decides | DRM is especially important |
| From the Search browser | Content blocking; hiding an element for good; extensions; a proxy per profile; driving pages from a socket and MCP (t136) | |
| Extensions | A study first | |
| Blocking lists | Well-known lists, fetched and updated; a list can be added by address | |
| Blocking by default | On | |
| Agent presets, the versions | Baked into the app when it is compiled; never fetched while it runs | |
| The disguise | A ladder the user chooses on: headers first; the script-visible identity later; feature probes later still | |
| Which setting wins | The most specific: site, then Space, then profile, then the default | |
| Sites known to need a disguise | A shipped list of site rules, on by default | Offering it when a site complains: a later study, not a priority |
| Per-site settings | One site panel from the address bar, and a section in the app's Settings listing all sites | |
| A site sent to a Space | Yes, set in the site panel and in Settings | |
| Bookmarks | A study: Safari's and the other browsers' | Import and export for any browser, simple and interoperable, at some point |
| Passwords | A study of what the system offers an app | Through extensions too, and in Sunset itself later if possible |
| Order | Agent and disguise, blocking, the site panel, then the studies | |

## The outcome, as one description

**Making sites load right.** Presets pass Sunset for Chrome, Edge, Safari or Firefox on macOS, Windows or Linux, and for Android and iOS, with
version numbers written in when the app is compiled. The disguise is a ladder: the first rung is the headers (User-Agent and client hints); the
second, later, the identity a script can read; the third, later still, feature probes. It can be set on a site, a Space, a profile, or as the
default, and the most specific wins. A list of sites known to need one ships with the app and applies by default; any rule can be turned off.

**Blocking.** Well-known lists are fetched, kept current, and compiled for WebKit's own blocker; more can be added by address; it is on by default
with a pause per site. An element of a page can be hidden for good on its site.

**The site panel.** One panel from the address bar holds everything that is per site: the disguise, the blocking pause, hidden elements, zoom,
permissions, keep awake, and the Space the site goes to. Settings has the same for all sites.

**A proxy per profile**, applied to every path of that profile's store.

**Studies**, each read back before anything is promised: what WebKit's extension engine runs today; bookmarks (what can be read of Safari's,
Chrome's and Firefox's, and one interoperable import and export); passwords (the system's Passwords and passkeys in our views, extensions, and
our own later).

**The engine, last.** A spike (t119) on a real build: can a WebKit built from the tip of main be loaded by our signed app, what it loses, its
size, build time and disk. Its findings are read back; DRM video matters especially. If it goes on: a second build of the app that carries the
engine in its bundle, WebKit unpatched, rebuilt on a schedule on the owner's machine, the cadence held by us.

Costs, as the owner asked to see them.
- **Security.** The own engine is the largest commitment here: between a WebKit security fix and our next build, its pages are exposed, and
  following the tip of main adds regressions nobody has tested. The owner chose a cadence over a fallback; while the project is local this
  binds only his own use. The blocking lists are third-party data fetched over https: they can block or hide, not run code. The app then makes
  requests nobody typed (the lists only; agent versions are never fetched). A disguise changes what a site sends us: Chrome-only code may arrive.
  Site-to-Space rules keep a site's logins in one profile.
- **Memory.** Compiled blocking rules are tens of MB, mapped from disk (to be measured). The second build is larger by the engine (several
  hundred MB on disk, unverified). The script identity adds a small script per frame.
- **Speed.** Blocking makes pages load less. Header rewriting costs nothing measurable; the script rung runs at document start in every frame.
- **Safety.** Each rung of the disguise can break a site in new ways; the per-site rule and the pause are the way back.

## Said plainly

- **DRM and the own engine.** Unverified, but likely: protected video (FairPlay) and passkeys depend on Apple's signed components, and a build of
  ours may not get them. The spike must test exactly this, and the owner decides after.
- "The tip of main" and "a cadence we hold" pull against each other: the newest code is also the least tested. The owner chose both knowingly; the
  schedule and what test gates a build are asked at that step.
- Hiding elements and the proxy were chosen without a place in the order: I put them after the site panel; the owner can move them.
- Not in this session: the extension decision itself (after its study), "offer a disguise when a site complains" (later study), switching engines
  without two builds (later study), distribution and updating of the app (not handled yet, by the owner's word).

## Steps proposed (each begins with its own questions)

| Step | What | Questions still to ask |
| --- | --- | --- |
| W-a | Agent presets and the first rung (headers); the build-time versions; site, Space, profile, default | Which presets exactly; where the build script reads versions; how a preset is chosen on a page |
| W-b | The shipped list of site rules | Who feeds it and how a rule is described |
| W-c | Blocking: lists fetched and compiled, on by default, the pause, adding a list | Which lists by default; how often; what the app says about its own requests |
| W-d | The site panel and the Sites section of Settings; a site sent to a Space | The panel's layout (sketches) |
| W-e | Hiding an element for good | How an element is picked |
| W-f | A proxy per profile | Kinds; where credentials are kept |
| W-g | The second rung: the script-visible identity | What is set, per browser |
| Studies | Extensions; bookmarks; passwords | |
| W-h | The third rung: feature probes | After W-g has been lived with |
| E | The own engine: the spike (t119), read back; then the second build | Schedule, test gate, what is lost |
