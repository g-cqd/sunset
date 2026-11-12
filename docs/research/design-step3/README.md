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
