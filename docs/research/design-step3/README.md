# Design step 3: every row, field and button, today and proposed (2026-11-12)

For the owner's review before anything is built. How they were made:
- **Off-screen** (`swift test --filter DesignCatalogTests` with `SUNSET_CATALOG=<folder>`; no window): the real `SidebarRow`, `SidebarGroupRow`,
  `FolderRow`, `SidebarIconButtonFace`, `ChoiceRowView`, with fake content. Hover cannot be forced from outside; "hover" is drawn with
  `keepCloseVisible`, which draws the same fill and close button. Liquid Glass and AppKit text fields do not draw off-screen.
- **In the app** (axdrive, in the background; the owner's frontmost app never changed): the address field in each place, the rename field,
  the history panel, the find bar, the command bar's input, the docked sidebar with Favorites.

| File | What |
| --- | --- |
| `rows-sidebar.png` | Tab rows, docked and floating, today and proposed: 1 line, selected, hover, selected + hover, marked, armed (busy close), kept-not-open, 2 lines (rest, selected, hover), and a stack as in the sidebar. |
| `rows-groups.png` | A split tab's row (rest, selected) and Favorites folders (open, closed), today and proposed. Folder names are AppKit fields and did not draw off-screen: see `app-sidebar-docked.png`. |
| `app-sidebar-docked.png` | The docked sidebar in the app with Favorites (folders open and closed, entries open and not, a separator, a split tab), today and with vertical padding 6. |
| `buttons.png` | The sidebar's buttons (docked 28, floating 24; rest, pressed, pinned) and the command bar's choice rows (rest, the keyboard's). |
| `app-fields.png` | Today's fields in the app: the sidebar field (plain, zoom, private), the page's own row (plain, zoom, private), the rename field, the history search, the find bar, the command bar's input. |
| `fields.png` | Mock-up of the shared Field: today's gaps and the proposed ones (lock ink 10 from the edge and from the text), on the sidebar, the window, a light page, private. |
| `bar-buttons.png` | Mock-up of the window bar's buttons: A today (system borderless), B the sidebar's IconButton (24, radius 6, hover and pressed fills), C bordered, standing in for glass buttons. |

## What the review found

1. **Two-line rows grew too in "proposed"** (36 → 42): they read the same `tabPaddingVertical`. Your answer was "two-line rows unchanged",
   so the build needs either a second key or the padding derived from the line count (6 for one line, 3 for two). Not decided.
2. **Folders and kept entries already pad more** than tabs (`tabPaddingVertical + 2` = 5 → 31 pt rows, `app-sidebar-docked.png` left), so
   today a folder row is taller than a tab row. With 6 the tab rows would be 32 and folders 36 unless folders drop their +2.
3. **The rename field in place** is a plain system field with its own fill and a radius that does not match the row's (the row's highlight is
   gone while renaming).
4. **The history panel** is drawn on its own: its search field is a different look (radius about 8, darker fill) from the sidebar's field;
   its rows pad 8 / 4 with no glyph (n67).
5. **The fields** today: edge to lock ink 10, lock to text 7.5; the zoom label sits 8 from the edge. The private field is near-black with a
   capsule label: its edge disappears on the dark window (`fields.png`, private row).
6. **The bar's buttons**: today they have no hover fill, unlike every other icon button in Sunset. B matches the sidebar's pin and +; C
   puts glass on glass.
7. **The command bar's input** shows its placeholder at 17 pt in a 48 pt field; its rows are 36 (left as their own component, as you said).

## Not shown

- The floating sidebar in the app: it only opens on hover, and the driver does not move the pointer. Its rows are in `rows-sidebar.png`.
- Real hover (only its stand-in), the pressed state of rows, the window's address bar (also hover-only), the suggestion list, download rows.
- Glass in the mock-ups (drawn grey).

## The owner's guidance (2026-11-12)

1. **Private marker**: a symbol instead of the word "Private".
2. **Spacing**: the more spaced variants are preferred. The Favorites tree may need to be more compact, without losing the larger hit
   areas of the new rows.
3. **Kept entries not open must not be dimmed** (they look disabled). Instead, an entry that is open gets a clearly more prominent look,
   and the regular tabs match that look; the not-open ones are drawn plainly.
4. **The trailing button** (close / unload) is as far from the row's trailing edge as from its top and bottom: not yet so in the proposals.
5. **The second line is monospaced** by default (a setting).
6. **A kept terminal that is not open** shows its own picture and name, not a folder and "Sunset": a terminal symbol with an initial when it
   runs a command, a folder symbol with an initial when it is a shell in a folder; its name is the command, or the folder's last component.
7. **Split tabs**: less inner padding so the sub-rows get more room; when narrow, a sub-row shows only its icon (or initial).
8. **Icons to research**: open and closed folders, the sidebar shown / hidden (the pin), downloads.
9. **The shared field and the icon buttons (B)**: good.
10. **Back, forward, reload**: their hit and hover area as tall as the address field beside them; the gaps to the bar's edge the same for
    every part of the bar.

## Second round, after the guidance (mock-ups, off-screen)

| File | What |
| --- | --- |
| `icons.png` | Symbol candidates. Folder closed → open: today folder / folder.fill; A folder / folder.badge.minus; B chevron.right / chevron.down (the disclosure convention of Finder and Xcode); C rectangle.stack / .fill; D square.stack / list.bullet.indent. Sidebar hides → kept: today sidebar.left both ways (filled when kept); A rectangle.leadinghalf.inset.filled / sidebar.leading; B pin / pin.fill; C sidebar.squares.leading / sidebar.leading. Downloads: today arrow.down.circle; A tray.and.arrow.down; B arrow.down.to.line; C square.and.arrow.down; D tray.full. Private: A theatermasks.fill, B eyeglasses, C sunglasses.fill, D eye.slash, E hand.raised.fill, F lock.shield.fill, G moon.fill. |
| `tree.png` | Nothing dimmed; an open entry (and every tab) marked: A an accent dot on the glyph, B an accent bar and a semibold title, C a faint fill. Each also compact: Favorites rows 28 with a 2 pt gap (tabs stay 32). The close buttons are drawn on every row to show their place; a real row shows one on hover only. |
| `row-details.png` | The close button 6 from every edge (from 4 trailing); the second line monospaced; a kept terminal not open with its own picture (folder + initial, terminal + initial) and its folder name or command. |
| `splits.png` | Split tabs with an inner padding of 2 (from 6), and icon-only sub-rows when narrow. |

Not mocked: the bar's buttons as tall as the field with equal gaps (the field is 26 and its gap to the bar's edge 6, so the buttons
become 26 × 26 hit areas at the same 6). It follows from guidance 10 directly; it will be shown in the app once built.

## The owner's choices, round 2 (2026-11-12)

- Private marker: **D, `eye.slash`**.
- Open entries: **C, a faint fill**; the compact Favorites tree (28 pt rows, 2 pt gaps): **as drawn**.
- Row details: as drawn, with the initial's place in the symbol refined.
- Split tabs: as drawn; sub-rows with icon and text aligned to the leading edge, icon-only sub-rows centred.
- Folders: more words than open/closed (expanded, collapsed, disclosure…), more variants.
- Sidebar pin: more rectangles with insets.
- Downloads: `arrow.down.circle` at rest; while downloading, the circle drawn as the progress, natively with the symbol if possible.

## Third round (mock-ups, off-screen)

| File | What |
| --- | --- |
| `r3-folders.png` | Collapsed → expanded. Picture changes: A folder / folder.fill, B folder.badge.plus / .minus, C folder.circle / .fill, D rectangle.compress / expand.vertical. A disclosure mark beside an unchanging folder, as Finder, Xcode and Mail do: E chevron.right / down, F the chevron and the folder filling, G triangles, H circled chevrons. |
| `r3-sidebar-button.png` | Hides → kept: A sidebar.leading → inset.filled.leadingthird.rectangle; B the half with an arrow → the filled third; C a small triangle in the third → filled third; D sidebar.squares.leading → filled third; E leadinghalf.filled → inset.filled.leadinghalf; F an empty rectangle → the filled third. |
| `r3-downloads.png` | At rest arrow.down.circle; downloading: A the symbol's own Variable Draw (`Image(systemName:variableValue:)` + `.symbolVariableValueMode(.draw)`, macOS 26), B today's drawn ring. |
| `r3-initials.png` | The initial in a kept terminal's picture, 3×: in the folder at centre, +1, +1.5, +2 pt (7 and 8 pt type); in the terminal symbol (its prompt collides) and in a plain rounded rectangle instead. |
| `r3-splits.png` | Sub-rows leading with icon and title, centred icon-only. |

Seen in the shots:
- **Variable Draw works on `arrow.down.circle`**: at 25 % the circle is drawn a quarter round, as the native symbol, with no drawn ring
  needed. Off-screen it is a still; the system animates between values, which is not shown here (to check in the app).
- **The initial**: in the folder it sits on the tab's line at centre; +1.5 at 8 pt reads centred in the body. In the terminal symbol it
  collides with the prompt; the plain rectangle is clean.

## The owner's choices, round 3 (2026-11-12)

- Split alignment: as drawn (`r3-splits.png`).
- Folder initial: 6.5 pt type, +1.75 pt down. Commands: another symbol, with no initial.
- Downloads: the native Variable Draw.
- Sidebar button: E (`rectangle.leadinghalf.filled` → `inset.filled.leadinghalf.rectangle`).
- Folders: F (the folder filling when expanded), with the disclosure mark at the row's trailing edge, where a tab's close button is,
  shown on hover; clicking it does what clicking the row does. Variants of the mark to be proposed.

## Fourth round (mock-ups, off-screen)

| File | What |
| --- | --- |
| `r4-disclosure.png`, `r4-disclosure-more.png` | Folder rows (F: the folder fills when expanded) with the mark in the close button's place, on hover only: A one chevron turning a quarter (right → down), B chevron down / up, C compact chevron, D plus / minus, E arrows apart / together, F diagonal expand / collapse, G triangles, H rectangles expand / compress. |
| `r4-command-symbols.png` | A kept terminal running a command, no initial: apple.terminal (.fill), terminal.fill, play.rectangle, play.square, bolt, bolt.horizontal, hammer, gearshape.2, curlybraces.square, greaterthan.square, chevron.forward.2, command.square, arrow.triangle.2.circlepath. And the folder's initial as chosen (6.5 pt, +1.75). |
