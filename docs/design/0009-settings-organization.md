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

- `appearance.scheme`: the app's scheme: the system's (the default), or always dark or always light.
  `appearance.contentFollows`, right below it: pages and documents use that scheme too (on by default); off, they use the
  system's. It replaces `web.pageScheme`: `app` reads as on, `system` as off, `light` or `dark` as on when it is the app's
  scheme, else off with a word.
- The look settings have a value in light and one in dark (`SettingsOption.inBothSchemes`, `Configuration.schemeKeys`):
  the window background, its material thickness, glass style, blur, tint and tint strength, the accent, the terminal's
  colors (the 16 ANSI colors too) and its background opacity. Each is macOS's until changed in that scheme; the other
  keeps macOS's. Bars and the sidebar's lists are one value for both.
- macOS's values, measured on macOS 27 (`NSColor` and the layers of `NSVisualEffectView` and `NSGlassEffectView`): a
  material background (the sidebar's: blur 30, saturation ×2.2 light and ×2.4 dark, `#f6f6f6` at 84% or `#282828` at
  80%), no tint, no extra blur, the system accent; the terminal on the text background (`#ffffff` and `#1e1e1e`) in the
  label color (black or white at 85%, `#272727` and `#dddddd` there), opaque; Kitty's palette in dark, Tomorrow's hues
  in light (`Configuration.nativeLight`).
- The window background is a color, a material or glass, each tinted by the tint at its strength. A color is the tint
  itself; with no tint, the window's own color, opaque. `opaque`, `fill` and `transparent` read as a color (`opaque` with
  no tint). The blur is offered with all three.
- In the file: one value is both schemes'; `{ "light": …, "dark": … }` each its own, a scheme left out keeping macOS's;
  `{}` macOS's in both. The writer writes only what was changed. The tint's former light keys
  (`appearance.tint.light`, `appearance.tint.lightAlpha`) read as its light values. A file with former values is
  written again once (`ConfigurationPatcher.upgraded`), the former one kept beside it.
- In Settings, a look setting shows its value in light and in dark, each under a sun or a moon; a Space's editor its
  color in each.

## File keys

The file's keys follow the sections. A former key is read, moved to its new place, and the file is rewritten once:

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
2. The pages' scheme: `appearance.contentFollows` (it replaced `web.pageScheme`). Done.
3. Light and dark values: the look settings, macOS's in each scheme until changed there. Done.
4. The file keys. Done: written under the new keys (`FileKeys`); a file with the former ones is still read, and moved once
   as it was written, comments kept, the former file beside it as `config.json.before-keys`. Inside, the settings keep
   their former names (Settings, Help and search use them); a theme may use either.
