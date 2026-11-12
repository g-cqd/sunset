---
status: for the owner's reading
date: 2026-11-12
asked-in: roadmap 0028 "The design system" (t216); the owner's answer "i'd prefer the design study first"
---

# A design system for Sunset and SunsetShell: what there is, what is wrong, what is proposed

Nothing here is built. Section 7 lists the decisions that are the owner's; they come back as questions before any step starts.

## 1. Sources, and what was not checked

- The code, on 2026-11-12, after commit 67dc1e0: `SunsetShell`, `SunsetWeb`, `SunsetApp`, `SunsetPane` (212 Swift files). The literals were
  counted by a script (regular expressions over `.padding`, `spacing:`, `cornerRadius:`, `.frame`, `.opacity`, `.font`, `.shadow`, colours and
  materials, comments left out). The counts are close, not exact: a value built from a variable (`layout.tabSideInset + 8`) counts once.
- Apple's documentation, read through the apple-docs index: SwiftUI `ConcentricRectangle`, `containerShape(_:)`, `ContainerRelativeShape`,
  `GlassEffectContainer`, "Applying Liquid Glass to custom views", `ControlSize`, and the HIG pages Materials and Layout.
- **Not checked:** how the system's own controls measure on macOS 27 (a standard bordered button's radius, a rounded text field's height and
  radius at each `ControlSize`). They need a probe that draws them off-screen and measures the pixels. The values below marked "(system)" are
  from memory of macOS 26 and must be measured before they are used.
- AemiSDR (`../AemiSDR`, its README): its variable blur is iOS-only (`VariableBlurUIView`); its backdrop blur works on macOS.

## 2. What there is today

### 2.1 The measures that are already shared

| Where | What | Notes |
| --- | --- | --- |
| `Configuration.Layout` (SunsetConfig) and `ShellSettings.Layout` (SunsetShell) | 30 `layout.*` keys: tab spacing, insets, paddings, radii, close button, lights, pin button, hairline, pane gap, inner corner, timings | **The same 30 fields written twice**, by hand; the bridge copies them. |
| `ConcentricRadius` | `inner(outer:inset:)`, the window's 16 pt | Used for the docked card, the floating panel and the pin button. Nowhere else. |
| `GlyphSpacing.toText` | 7 pt, glyph frame to text | From n63 and the spacing rule (docs/design/0002). |
| `SidebarHeader` | where the lights, the pin and the first tab sit | Derived from `layout.*`: the best-built part of the shell. |
| `SidebarButtonMetrics` + `SidebarIconButton` | one size and corner for the sidebar's buttons (28×28, radius 7 by default) | A real component. |
| `ChoiceList` / `ChoiceRow` / `ChoiceRowStyle` / `ChoiceRowFill` | rows of choices with hover 0.07, pressed 0.16, selected accent | A real component; its padding (6), row gap (2) and row height (36) are literals inside it. |
| `InsettableShape.hairline` / `hoverHairline` / `focusHairline` | the card's line | Reads `layout.hairline*`; the focus line's 0.85 is a literal. |
| `WindowLook` / `SidebarLook` | material, glass, tint, blur behind the window and the floating sidebar | Configuration-driven. |

### 2.2 The measures that are not shared (literals in views)

| Kind | Uses | Distinct values | The values, most used first |
| --- | --- | --- | --- |
| padding | 67 | 35 | 6, 10, 4, 8, 14, 8, 4, 12, 16, 2, 10, 8, 20; once each: 3, 5, 24, 26, 52, 56, 72 |
| stack spacing | 75 | 10 | 4 (28×), 6, 8, 0, 2, 10, 12, 1, 3, 14 |
| corner radius | 21 | 11 | 4, 12, 14, 6, 10, 3.5, 5, 7, 8, 16, 24 |
| fixed frame | 56 | 46 | glyph 18 (6×), bars 34/36/46, fields 26, widths 170/260/300/320/340/360/420/460/520 |
| opacity | 41 | 24 | 0.04, 0.06, 0.07, 0.08, 0.1, 0.15, 0.16, 0.18, 0.2, 0.22, 0.24, 0.25, 0.28, 0.3, 0.35, 0.4, 0.5, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85 |
| font | 80 | 27 | `.caption` 30×, `.headline` 11×, `.callout` 6×; fixed sizes 7, 9, 10, 12, 13, 14, 15, 17, 22, 28, 64 |
| colour | 86 | 16 | `.secondary` 52×; the accent two ways: `Color(nsColor: .controlAccentColor)` 8× and `Color.accentColor` 6× |
| shadow | 6 | 5 | black at 0.2/0.25/0.28/0.3, radius 10/12/14/16/24, y 4/6/8 |
| material | 14 | 10 | `glassEffect(.regular)` 6× (each with its own shape), `.ultraThinMaterial`, `.regularMaterial`, `NSVisualEffectView` 4× |

56 of the 212 files hold at least one such literal.

## 3. What is wrong

1. **Corners that do not nest.** A container's radius should be its child's radius plus the inset between them (what `ConcentricRectangle` does).
   | Container | Its radius | Inset | Child radius | Concentric child would be |
   | --- | --- | --- | --- | --- |
   | Command bar | 14 (`tabRadius + 8`) | 6 (ChoiceList) | 6 | 8: **off by 2** |
   | Suggestion list | 12 | 6 | 6 | 6: right |
   | Actions panel | 12 (`radius + 6`) | 6 | 6 | 6: right |
   | Window address bar | 12 | 5 vertical, 6 horizontal | field 7 | 7 or 6: **two insets** |
   | Find bar | capsule (17) | 6 | system field (~5) | 11: **off by 6** |
   | Tab preview | 10 | 6 | 4 | 4: right |
   | Permission panel | 14 | 14 | system buttons | 0: the panel's padding is its radius, so nothing inside can nest |
   The right ones are right by arithmetic done by hand, not by a rule.
2. **Off-grid values.** Most values are on a 2 pt grid, but 3, 5, 10, 14, 26, 34, 46 and 3.5 sit next to 4, 6, 12, 16, 24, 36, 48 doing the
   same job. Two floating panels have 14 and 12 for the same thing.
3. **24 opacities for about five meanings**: a faint fill, hover, pressed, a separator, dim text. Hover is 0.07 in rows and 0.1 in the tab bar.
4. **Five shadows for two meanings** (a popover, a floating panel).
5. **Two accents.** `controlAccentColor` (the system's) and `Color.accentColor` (the app's tint, which can differ). Rows are selected in one and
   the card's focus line drawn in the other.
6. **Liquid Glass without a container.** The address bar and its suggestion list are separate `glassEffect`s, so they render apart and cannot
   merge or morph. Apple's article asks for a `GlassEffectContainer` around glass that sits together, for rendering cost as well.
7. **Glass and materials mixed by habit.** The HIG keeps Liquid Glass for the functional layer (bars, sidebars, popovers) and standard materials
   for the content layer. The tab preview (`.ultraThinMaterial`) and the pane-area capsule (`.regularMaterial`) are functional-layer elements
   drawn in content-layer material, next to glass ones.
8. **Fixed font sizes for glyphs and text alike.** 11 sizes. Text should use text styles; SF Symbols should use a few symbol sizes.
9. **Layout written twice** (`Configuration.Layout` and `ShellSettings.Layout`): every new key is added in two places, with two defaults that
   can drift. The pin button keys (`pinButtonSize` 24, `pinButtonRadius` 5) and `SidebarButtonMetrics` (28, 7) say different things about the
   same button, depending on docked or floating.
10. **Panels built by hand.** HistoryPanel, DownloadsList, PermissionPanel, WebFindBar, the sheets (ClearHistorySheet, QuitSheet,
    CommandSheet) each choose their own header font, padding (12, 14, 16, 20) and width (320, 360, 420, 460). n67's complaint about the history
    panel is this.

## 4. What Apple offers, and what to use

- **`ConcentricRectangle` + `containerShape(_:)`** (macOS 26): a shape whose corners follow the container's, computed. Sunset's
  `ConcentricRadius.inner` does the same by hand. Using the system's shape removes the arithmetic from every view: a panel sets its shape once
  with `containerShape`, its rows draw `ConcentricRectangle()`. Caveat: the rows of a scroll view are not at a fixed inset from the container's
  corner; a row in the middle of a list is not "near the corner". Rows keep a fixed radius (the leaf radius); only the container is derived
  from them (radius = leaf + inset), which is the same rule run the other way.
- **`GlassEffectContainer(spacing:)`**: one per group of glass that sits together (address bar + suggestions; command bar + actions panel;
  the find bar and its buttons). `glassEffectID` for the morphs (the suggestion list growing out of the bar).
- **`Glass.regular` vs `.clear`**: regular for anything with text (every Sunset bar). `.tint()` for prominence, `.interactive()` for custom
  controls. Used sparingly, per the HIG.
- **`ControlSize`** (`.mini`, `.small`, `.regular`, `.large`, `.extraLarge`): the system's control heights. Sunset's buttons and fields should
  pick a control size rather than a frame height, where they are system controls.
- **`ButtonStyle`** (custom) and `.glass` / `.glassProminent` button styles: Sunset's own styles (`ChoiceRowStyle`, `SidebarIconButtonStyle`)
  are the right shape of thing; the system's glass styles fit buttons that sit alone on content (the find bar's arrows).
- **Text styles** (`.headline`, `.body`, `.callout`, `.caption`) and SF Symbols' `imageScale` / `.font(.system(size:))` for glyphs.
- **Variable blur** (n60): not in SwiftUI. AemiSDR's is iOS-only; on macOS it would be a `CAFilter` `variableBlur` through SunsetPrivate, like
  `BackdropBlur` today. A probe first.

## 5. The proposal

### 5.1 Tokens (one Swift namespace, `Design`, in SunsetShell; SunsetWeb and SunsetApp read it)

**Spacing**: a 2 pt base, values on a scale. Each off-scale value moves **up** to the next step (the spacing rule).

| Token | pt | Replaces |
| --- | --- | --- |
| `space.hair` | 2 | 1, 2 |
| `space.xs` | 4 | 3, 4 |
| `space.s` | 6 | 5, 6 |
| `space.m` | 8 | 8 |
| `space.l` | 12 | 10, 12 |
| `space.xl` | 16 | 14, 16 |
| `space.xxl` | 24 | 20, 24 |

**Radii**: two chosen, the rest derived.

| Token | Value | Rule |
| --- | --- | --- |
| `radius.window` | 16 (measured) | The system's. |
| `radius.leaf` | 6 = `layout.tabRadius` | A row, a field, a control inside a container. |
| `radius.small` | 4 = `layout.closeButtonRadius` | A thumbnail, a close button, a badge. |
| `radius.container(inset)` | leaf + inset | A bar or panel holding leaves: 6 + 6 = 12 for every floating surface. |
| docked card, floating panel | `ConcentricRectangle` on the window | As today, by the system's shape. |

The command bar becomes 12 (from 14) or keeps 14 with an 8 inset (Q2). The find bar stops being a capsule or its field becomes one (Q3).

**Sizes**

| Token | pt | For |
| --- | --- | --- |
| `size.glyph` | 18 frame, 15 symbol | A row's glyph (today's value). |
| `size.control` | 24 | Icon buttons in bars, close buttons grow 20 → 24? (Q4). |
| `size.sidebarButton` | 28 | `SidebarButtonMetrics`. |
| `size.bar` | control + 2 × `space.s` = 36 | Address bar, find bar (34 → 36), actions header (34 → 36). |
| `size.field.large` | 48 | The command bar's input (46 → 48). |
| `size.row` | 36 | `ChoiceList.rowHeight`. |
| `width.panel` | 320 / 360 / 420 / 520 | Four widths for popover, panel, sheet, command bar (from nine). |

**Type**: text by style only: `title` = `.headline`, `body`, `secondary` = `.callout`, `detail` = `.caption`, `mono` = `.body.monospaced()`.
Symbols by four sizes: `symbol.badge` 9, `symbol.row` 13, `symbol.bar` 15, `symbol.hero` 28 (and the download card's 64 as a one-off
illustration).

**Colour and fill**: `ink.secondary` (`.secondary`), `ink.tertiary`; fills `fill.hover` 0.07, `fill.pressed` 0.16, `fill.selected` the accent,
`fill.faint` 0.04; `line.hairline` (`layout.hairline*`), `line.focus` (the accent, 0.85); `dim.scrim` 0.35 (the HIG's figure for a dimming
layer). One accent (Q5).

**Elevation**: `shadow.popover` (black 0.25, radius 14, y 6) and `shadow.float` (black 0.3, radius 24, y 8).

**Surfaces**: `surface.bar` and `surface.panel` = `Glass.regular` in `radius.container`; `surface.content` = a standard material; the window and
sidebar keep `WindowLook` / `SidebarLook` (they follow the configuration).

**Motion**: `motion.smooth` = `layout.animation` (exists); `motion.hide` = `layout.hideDelay`.

### 5.2 Components

| Component | Today | Becomes |
| --- | --- | --- |
| `Row` | ChoiceRow/ChoiceRowFill, SidebarRow, HistoryRow, DownloadRow each pad and fill alone | one row: glyph slot, title, detail, trailing accessory, the three fills |
| `IconButton` | SidebarIconButton, WindowAddressBar's buttons, WebFindBar's buttons | SidebarIconButton generalised (its metrics from the environment, already) |
| `Field` | AddressField (radius 7, height 26), the sidebar field, HistoryPanel's TextField | one field: `radius.leaf`, height `size.control` + 2 |
| `Bar` | WindowAddressBar, WebFindBar, CommandBarActionsPanel header | `size.bar`, `space.s` inset, `surface.bar`, in a `GlassEffectContainer` |
| `Panel` | PermissionPanel, DownloadsList, HistoryPanel, IconPopover, SiteSettingsPopover | header (title + close), content, footer; `space.l` padding; `width.panel` |
| `Sheet` | ClearHistorySheet, QuitSheet, CommandSheet | title, message, content, buttons trailing; `space.xxl` padding |
| `SurfaceList` | ChoiceList in the command bar, suggestions, actions | ChoiceList, its padding and gap from tokens |

### 5.3 The configuration

The `layout.*` keys stay, and stay the owner's to tune: they become the **source** of the tokens they name, not copies.

| Key | Token |
| --- | --- |
| `tabRadius`, `floatingTabRadius` | `radius.leaf` (docked / floating) |
| `closeButtonRadius` | `radius.small` |
| `tabSpacing` | the row gap in the sidebar |
| `tabPaddingLeading/Trailing/Vertical` | `Row`'s padding in the sidebar |
| `closeButtonSize`, `pinButtonSize`, `pinButtonRadius` | `size.control`, `size.sidebarButton`, its radius (one meaning each: Q6) |
| `hairlineWidth`, `hairlineOpacity` | `line.hairline` |
| `animation`, `hideDelay` | `motion.*` |
| `terminalRadius`, `panelRadius`, `innerCornerRadius`, `paneGap` | the window-level surfaces |
| (none) | spacing scale, type, fills, shadows, panel widths: fixed in code, not settings (Q7) |

`ShellSettings.Layout` stops being a hand copy: it is generated from (or replaced by) one list of fields, so a key is added once.

### 5.4 Enforcement

A source test like `SourceStructureTests`: in view files of `SunsetShell`, `SunsetWeb`, `SunsetApp`, a numeric literal is an error inside
`.padding(`, `spacing:`, `cornerRadius:`, `.opacity(`, `.shadow(`, `.font(.system(size:` and `RoundedRectangle(`, except `0` and in the token
file. During the migration it carries a list of files still allowed, which may only shrink (a file leaving the list cannot come back). `.frame`
is left out at first: many frames are content sizes (a thumbnail, a preview).

## 6. Migration, in steps, with their cost

| Step | What | Size | Visible change |
| --- | --- | --- | --- |
| 1 | `Design` tokens, the test with all 56 files allowed; one Layout list instead of two | ~1 day | none |
| 2 | Surfaces: Bar, Panel, Sheet, shadows, `GlassEffectContainer` groups; the radii made concentric | ~1 day | corners, a few 2 pt moves |
| 3 | Row, Field, IconButton; ChoiceList on tokens | ~1 day | row paddings (this is 0028 step A, n66) |
| 4 | Type and fills; one accent | half a day | small |
| 5 | The rest of the files, until the allowed list is empty | ~1 day | none intended |
| then | 0028 B (history panel on Panel + Row), C (bars' blur, after a variable-blur probe), D (loading ring) | as planned | |

Each step: build, tests, and screenshots of the same windows before and after through axdrive (background only), compared side by side for
the owner.

## 7. Decisions that are the owner's

- **Q1** The spacing scale (2, 4, 6, 8, 12, 16, 24), with off-scale values moving up.
- **Q2** The command bar: radius 12 with a 6 inset like the other surfaces, or 14 with an 8 inset (more space).
- **Q3** The find bar: a rounded bar like the address bar (12), or a capsule with a capsule field.
- **Q4** The close button and bar icons: 20 → 24 to share `size.control`, or keep 20.
- **Q5** One accent: the system's (`controlAccentColor`) or Sunset's tint (`Color.accentColor`, which follows `appearance.tint`?).
- **Q6** The pin button's two sizes (24 floating via `pinButtonSize`, 28 docked via `SidebarButtonMetrics`): one meaning per key.
- **Q7** Which tokens are settings: only today's `layout.*` keys, or also the spacing scale and panel widths.
- **Q8** Glass: the tab preview and the pane-area capsule move from materials to glass (functional layer), or stay.
- **Q9** Order: the migration (steps 1–5) before 0028 A–D, or each 0028 step migrating the files it touches.

## 8. The owner's answers (2026-11-12)

| Question | Answer |
| --- | --- |
| Q1 Spacing | The scale 2, 4, 6, 8, 12, 16, 24, off-scale values moving up. **Optical adjustments must stay possible** (a named, documented nudge, not a stray literal). Add design research and proper documentation, such as grid systems (Josef Müller-Brockman). |
| Q2 Command bar | Radius 12, inset 6, like the other glass surfaces. |
| Q3 Find bar | A rounded bar (12) like the address bar. |
| Q4 Control size | Two sizes: small 20 (close buttons), regular 24. |
| Q5 Accent | Configurable, since more tinting and customisation will come: the system's accent, Sunset's own, and a neutral variant (black / grey / white shades); following the system stays possible. |
| Q6 Pin button | Both sizes kept, as two named keys (docked / floating). |
| Q7 Settings | Only today's `layout.*` keys; the rest fixed in code. |
| Q8 Glass | The tab preview and the pane-area capsule move to glass. And: **glass, material, opaque or transparent becomes one general setting** across every place a surface is drawn. |
| Q9 Order | Migration steps 1 to 5 first, then roadmap 0028 A to D on top. |

Consequences for the plan:
- Before step 1: a written design document (`docs/design/0003-design-system.md`) with the grid research (Müller-Brockman's grid systems, the
  8 pt / 4 pt grids of current practice, Apple's layout guidance), the tokens, the components, and the rule for optical adjustments
  (`Design.optical(…)` with a reason, allowed by the enforcement test).
- Step 1 gains: `appearance.accent` (system / sunset / neutral) and a surface setting (glass / material / opaque / transparent) read by every
  surface token. Both are new configuration keys (the key count rises from 108).

## 9. Migration step 1: the owner's answers (2026-11-12)

| Question | Answer |
| --- | --- |
| Surfaces | `window.material` itself governs every surface (one key). Later: a tint chosen for surfaces specifically, and spaces each customisable. |
| Accent | `sunset` is the existing `appearance.tint.color`; the system's accent when it is unset. |
| Pin keys | Something more generic: other sidebar buttons (the + at the bottom) should share the keys. Done as `layout.sidebarButtonSize` (floating size; docked derived from the lights' row) and `layout.sidebarButtonRadius` (docked corner; floating concentric with the panel); the old `pinButton*` names are still read. |
| Scope | Tokens, the test with every current file allowed, one Layout list, the new keys, and the system controls measured off-screen; nothing visible changes. |

## 10. The system's controls, measured off-screen (2026-11-12, macOS 27.0.1)

Probe: `probes/system-controls.swift` (draws into 2x bitmaps; no window is created or shown).

| `ControlSize` | mini | small | regular | large | extraLarge |
| --- | --- | --- | --- | --- | --- |
| Push button and pop-up, AppKit's fitting height | 16 | 20 | 24 | 28 | 36 |

- These heights are AppKit's own numbers and agree with design 0003: `Size.controlSmall` 20 is the system's small, `Size.control` 24 its
  regular, `Size.sidebarButton` 28 its large, `Size.bar` 36 its extra large.
- **Corners: not measured.** `cacheDisplay` does not draw the bezels of macOS 27's buttons and pop-ups (they are drawn by layers outside it):
  only the titles came out, 6.5 to 13.5 pt tall. The rounded text field drew, but at 24 pt for every size, which is not believable, so its
  corners (2 to 6.5 pt) are not used either. Measuring them needs a window composited by the system, which this probe does not open. Nothing in
  the design depends on them: Sunset's leaf radius is its own (`layout.tabRadius`), and its fields and buttons are drawn by its components.

## 11. Migration step 2: the owner's answers (2026-11-12)

| Question | Answer |
| --- | --- |
| Default surface | Glass for everything. The owner's own settings become the defaults: `window.material` glass, tint #000000 at 0.5, terminal opacity 0.2, background #000000; decorations none, window padding 4; sidebar on the right, padding 4, kept visible, width 229; JetBrains Mono 12 (the system's monospaced when it is missing); bar cursor, blink stopping after 15 s. |
| Transparent | No "transparent": a **colour fill** with alpha, the tint's colour and alpha, for the window and every surface; no other material under it. The old value `transparent` is read as `fill`. The desktop blur "never really worked": a fill has none. |
| Opaque | Floating parts slightly lighter than the window (a raised surface), with the hairline and the shadow. |
| Shadows | Ours on every kind of surface; the differences to be shown to the owner. |
| Glass groups | Group only, no new animation. Growing out of the bar is not decided: shown first, maybe a setting. |
| Panel padding | The space between a panel's edge and what it holds: 16 ("standard"), to be shown. |

## 12. Migration step 2: what was built, and the shots (2026-11-12)

- `SurfaceStyle` (SunsetShell; built from the configuration in SunsetShellBridge) and `View.surface(_:shadow:)`: every floating surface drawn
  by `window.material`: glass (regular or clear), material (drawn behind as a shape: `.background(_:in:)` made the text vibrant and nearly
  invisible over a light page), opaque (raised: the window's colour 6 % lighter), fill (the tint's colour and alpha). With the hairline; the
  shadows `popover` and `float`.
- Moved onto it: the address bar and field, the suggestion list, the find bar (a rounded bar now), the permission panel, the command bar
  (radius 12, its rows' 6 nested at 6), the actions panel, the tab preview, the pane-area label, and the floating sidebar (no longer always
  glass). The address bar and its list share a `GlassEffectContainer` (spacing 0); the command bar and its actions panel do not (the panel
  overlaps the bar, and a container would merge them).
- Measures: the address bar is 38 (from 36: field 26 + 6 + 6, so the field's corner nests); the find bar 38 (from 34); the permission panel
  pads 16 (from 14) with a radius of 22 (6 + 16: its buttons in the corner nest); popovers pad 16; sheets 24.
- Found and fixed: the menus' enabled state did not follow `TabRegistry.actingWindow` (it did not read `revision`), so Find… was disabled
  while Sunset was in the background.
- Shots: `design-step2/surfaces-2026-11-12.png` (the permission panel, the find bar, the command bar; before with glass, after with each kind).
  The "before" row has no find bar (that build had the menu bug). **Not shown:** the window's address bar (it comes out on hover, and the
  driver does not move the pointer), the suggestion list (a value set from outside does not start typing), the floating sidebar.
- Seen in the shots: with `fill` (black at 0.5, the default tint) the page shows through the panel's text and is hard to read.

Owner, after the shots: the permission panel's 16 and 22 kept; shadows fine; the find bar as a rounded bar fine; with `fill`, floating parts
use the tint's colour at least 0.85 opaque (`Design.Fill.floatingMinimum`), the window keeps the tint's alpha.

## 13. Migration step 3: measured, and the owner's answers (2026-11-12)

Measured on a selected docked row (2x shot, background): edge to the glyph's ink 9 pt leading. One-line row (26 pt): glyph ink 6.5 pt from
the top, 6 from the bottom. Two-line row (36 pt): 11.5 and 11.

| Question | Answer |
| --- | --- |
| What is 9 above and below | The glyph's ink: one-line rows grow 26 → 32; two-line rows unchanged. |
| Floating panel | Its keys stay; it should look as padded to its edges and content as the docked sidebar does: checked by shots. |
| Shared Row | Sidebar tabs, folders, groups, history rows. The command bar's rows are a different component and may differ. |
| Shared Field | The address field, the sidebar field, the history search, the rename field; its edges must show in every place (checked). |
| Field's leading parts | The lock and the zoom label follow the row rule. |
| Icon buttons in bars | To be decided by what is most consistent there (investigated, shown). |

## 14. Migration step 4: text, fills, accent (2026-11-12)

Owner's answers: the accent applies everywhere, Sunset's parts and the system's controls inside it (`tint`); neutral is light grey with dark
ink on a dark window (dark grey, light ink on light); "sunset" with a tint too dark or too light (relative luminance outside 0.08–0.85) is
the system's accent; red stays red for destructive states; text by Apple's HIG; fills built, then shown.

- HIG, Typography (read 2026-11-12): macOS has no Dynamic Type; use the built-in text styles so text matches the system's controls.
  Measured on macOS 27.0.1: headline 13 semibold, body 13, callout 12, subheadline 11, footnote and caption 10, title3 15, title2 17.
  `Design.Text`: title (headline), body, secondary (callout), small (subheadline), detail (caption), tiny (caption2), heading (title3),
  input (title2), mono. Every `.font(.caption)` and the like in views now names one; fixed symbol sizes are `Design.Symbol` steps.
- `Design.Accent.style(dark:)` → `AccentStyle` (colour and ink), set per window by `.accent(_:tint:)` (`\.accent` and `tint`), also on the
  Settings window. Every accent use (14) reads it.
- Fills: selected (and inactive), marked, target, armed (and its line and button), pressed accent, ink secondary, backdrop, separator,
  fainter divider, note background, collapsed icon: every opacity literal in views is now a named fill.
- Shots: `design-step2/accents-2026-11-12.png`, the command bar's selected row before, and with system, sunset (#E8743B), sunset with the
  owner's black tint (falls back to the system's), neutral.

Not verified: the system controls' tint in Settings (Settings was not opened), the accent in a light scheme, the drop and marked fills
(they need a drag and several selected rows, which the driver does not do).

## 15. Migration step 5: the owner's answers (2026-11-12)

| Question | Answer |
| --- | --- |
| Off-scale values | Move up to the scale; an optical token only with a measured reason. Many were probably chosen by eye: each is shown, today and moved up, for the owner to say which are optical. |
| Settings window | Migrated onto the same tokens. |
| History panel | Roadmap 0028 B done in this step: rebuilt on the sidebar's parts. |
| Built-in tab bar | Migrated and shown. |
| Frames | Added to the enforcement test; content sizes become named tokens. |
