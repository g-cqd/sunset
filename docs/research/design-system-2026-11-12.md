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
