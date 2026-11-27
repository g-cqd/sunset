# 0009 — How Settings is organized

The owner, 2026-11-27: Settings grew by accretion. Web settings sat under General and Privacy, the vault under Privacy,
the terminal's under Appearance, Window and Privacy, and one color scheme drove the app and the pages alike. This is the
organization that replaces it, and the order the work lands in.

## Sections

App sections first, then one section for each feature scope, listed only while its scope is on (`features.*`):

| Section | Topics |
|---|---|
| General | Features · Startup and quitting · Updates · Keyboard shortcuts · Control from outside · Configuration file |
| Look and feel | Appearance (the app's scheme, app icon) · Accent and tint · Materials · Feedback (haptics) |
| Windows and tabs | Window · Tabs and sidebar · Tab labels · Previews and Library · New tabs · Floating sidebar · Spaces |
| Privacy and storage | What is kept · Key and recovery · Export |
| Terminal | Text · Colors · Cursor · Scrolling and history · Shell · Programs · Advanced |
| Web | Address and bars · Search · Pages · Downloads · Websites · Each site · Profiles · Privacy · Blocking · Extensions · Memory · Proxy · Advanced |
| Documents | Editing · Library |
| Passwords | Locking · Filling in pages · Backups |

- What a scope owns is in its section and nowhere else: the terminal's colors, padding and opacity in Terminal; the
  web's protection, history and site data in Web; the vault in Passwords.
- "Look and feel" holds what the whole app looks and feels like; a scope's own look (the terminal's colors) stays in the
  scope, so that turning the scope off takes it away.

## Light and dark

- `appearance.scheme`: Sunset's scheme (light, dark, follow the system).
- `web.pageScheme`: the pages' (follow Sunset, follow the system, light, dark). A page with a dark mode of its own uses it;
  the others are left as they are.
- A color setting can have one value, or one for light and one for dark: in Settings, a "Separate for light and dark"
  switch shows two wells; in the file, a value or `{ "light": …, "dark": … }`. Tint, accent color, bar tint, the
  terminal's colors and a Space's color work this way.

## File keys

The file's keys follow the sections. An old key is read, moved to its new place, and the file is rewritten once:

| Old | New |
|---|---|
| `font.*` | `terminal.font.*` |
| `colors.*` | `terminal.colors.*` |
| `cursor.*` | `terminal.cursor.*` |
| `scrollback.lines` | `terminal.scrollback` |
| `scroll.*` | `terminal.scroll.*` |
| `keyboard.optionAsMeta` | `terminal.optionAsMeta` |
| `window.padding` | `terminal.padding` |
| `window.material`, `window.materialThickness`, `window.blur` | `appearance.material`, `appearance.materialThickness`, `appearance.blur` |
| `sidebar.documentSort` | `documents.sort` |
| `features.credentials` | `features.passwords` |

## Order of the work

1. Sections and topics as above (Settings only; no key changes). Done.
2. `web.pageScheme`, in Web › Pages ("Page appearance"). Done.
3. Light and dark values for color settings, and a Space's color for each.
4. The file keys, with the old ones migrated.
