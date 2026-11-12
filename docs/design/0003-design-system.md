# Design 0003 — The design system

Intended design of Sunset's interface measures, surfaces and components. Why: the study `docs/research/design-system-2026-11-12.md` and the
owner's answers in its §8. **Nothing in it is built yet**; the migration is roadmap 0028's design section, steps 1 to 5 (t222).

## 1. Principles

1. **A measure has a name.** A view never writes a number for a space, a corner, an opacity, a font size or a shadow; it names a token. The
   token says what the number is for, so two things that are the same are the same number, and two that differ differ on purpose.
2. **Few values, on one grid.** A 2 pt base, a 4 pt step for most things (§3).
3. **Corners nest.** An inner corner shares its centre with the outer one: inner radius = outer radius − inset. Two radii are chosen (the leaf
   and the small one); every container's radius is derived from what it holds.
4. **When two gaps must match, the smaller grows** (docs/design/0002).
5. **The eye has the last word, in writing.** An optical adjustment is allowed, but it is a named token with its reason and its measurement
   (§4), never a stray literal.
6. **Glass for the functional layer, material for the content layer** (Apple's HIG, Materials), and the person chooses which (§6).
7. **The system's parts first.** A system control, shape or style is used where it fits (`ConcentricRectangle`, `GlassEffectContainer`,
   `ControlSize`, text styles); Sunset's own components are for what the system has not.

## 2. The grid: what the research says

### 2.1 Josef Müller-Brockman, *Grid Systems in Graphic Design* (1981)

From memory of the book; **not re-read for this document** (no copy at hand). The claims below are the book's well-known ones; page
references are not given because they were not checked.

- **The grid is derived from the type**, not drawn first. The body text's size and leading set the line interval; the height of a field is a
  whole number of lines, and the space between fields (the gutter) is one line or more. Everything aligns because everything counts in lines.
- **Fields and gutters.** The page is divided into fields of equal size separated by equal gutters; an image or a block of text spans one or
  several whole fields, never a part of one. Common divisions: 2 × 4, 4 × 5, 4 × 8 fields; the more fields, the more freedom and the more
  discipline it needs.
- **Margins are part of the proportion**, usually unequal (wider at the foot), and chosen with the grid, not left over from it.
- **Few sizes, clear hierarchy.** A small number of type sizes and weights; hierarchy by position, size and space rather than by ornament.
- **The grid is a means, not an end.** It brings order, clarity and objectivity ("the will to systematic thinking"), and the designer departs
  from it knowingly, not by accident.

### 2.2 The 4 pt and 8 pt grids of current practice

From general knowledge, **not checked against a source for this document**: screen design systems (Google's Material Design is the best known)
put every size and space on multiples of 8, with 4 for small parts (icons, text insets), because 8 divides evenly at the screen scales in use
(1×, 2×, 3×) and gives a visible rhythm with few values. Apple publishes no grid as such; its HIG Layout page speaks of consistent margins,
alignment and the system's spacing, and its own controls are mostly on even numbers (read on 2026-11-12; the page gives no table of values).

### 2.3 What Sunset takes from them

| From | Sunset |
| --- | --- |
| The grid comes from the type | The row is the module: a sidebar row, a choice row, a bar are built from the control size plus insets, not chosen freely (§3.3). Text sits on the system's text styles, whose line heights the rows contain. |
| Fields and gutters | The window is a few fields: the sidebar, the cards, the bars. The gutter between them is one token (`layout.paneGap`, or the sidebar's margin when docked), the same everywhere. |
| Margins in the proportion | The window's margin is the sidebar's `padding`; the lights sit at `margin + lightsInset` on both axes (`SidebarHeader`, already). |
| Few sizes | Seven spaces, two chosen radii, two control sizes, five text styles, four symbol sizes, two shadows. |
| The grid is a means | Optical adjustments (§4). |
| 4 / 8 pt grids | A 2 pt base with a 4 pt step; 2 and 6 kept because the shell's dense parts (sidebar rows, insets around rows in a list) need them. |

## 3. Tokens

In one namespace, `Design`, in SunsetShell (SunsetWeb and SunsetApp import it). Values are points.

### 3.1 Space

| Token | pt | Typical use |
| --- | --- | --- |
| `Design.Space.hair` | 2 | between rows of a list; title to subtitle |
| `Design.Space.xs` | 4 | between items in a bar; between rows of the sidebar (`layout.tabSpacing`) |
| `Design.Space.s` | 6 | a container's inset around its leaves |
| `Design.Space.m` | 8 | a row's leading padding |
| `Design.Space.l` | 12 | a panel's padding |
| `Design.Space.xl` | 16 | between groups in a panel |
| `Design.Space.xxl` | 24 | a sheet's padding |

A value between two steps moves up to the next one (owner, Q1).

### 3.2 Radius

| Token | Value |
| --- | --- |
| `Design.Radius.window` | 16, measured (`ConcentricRadius.standardWindow`) |
| `Design.Radius.leaf` | `layout.tabRadius` (6): a row, a field, a control inside a container |
| `Design.Radius.small` | `layout.closeButtonRadius` (4): a close button, a thumbnail, a badge |
| `Design.Radius.container(holding:inset:)` | leaf + inset: 6 + 6 = 12 for every floating surface (address bar, find bar, command bar, suggestions, actions, panels) |
| window-level surfaces | the docked card and the floating panel: concentric with the window (as today; `ConcentricRectangle` where it fits) |

Rows inside a scroll view keep the leaf radius: they are not at a fixed distance from the container's corner, so they cannot be concentric with
it; the container is derived from them instead.

### 3.3 Size

| Token | pt | For |
| --- | --- | --- |
| `Design.Size.glyph` | 18 (frame), 15 (symbol) | a row's glyph |
| `Design.Size.controlSmall` | 20 = `layout.closeButtonSize` | close buttons |
| `Design.Size.control` | 24 | icon buttons in bars, the floating pin button |
| `Design.Size.sidebarButton` | 28 | the docked sidebar's buttons |
| `Design.Size.bar` | control + 2 × `Space.s` = 36 | address bar, find bar, actions header |
| `Design.Size.fieldLarge` | 48 | the command bar's input |
| `Design.Size.row` | 36 | a choice row |
| `Design.Width.popover / panel / sheet / commandBar` | 320 / 360 / 420 / 520 | widths |

### 3.4 Type

Text by style: `Design.Text.title` (`.headline`), `.body`, `.secondary` (`.callout`), `.detail` (`.caption`), `.mono` (`.body.monospaced()`).
Symbols by size: `Design.Symbol.badge` 9, `.row` 13, `.bar` 15, `.hero` 28. A one-off illustration (the download card's 64) is an optical
token (§4).

### 3.5 Colour, fill, line

- Ink: `.primary`, `Design.Ink.secondary`, `.tertiary` (the system's vibrant label colours).
- Fills: `Design.Fill.faint` 0.04, `.hover` 0.07, `.pressed` 0.16, `.selected` = the accent.
- Lines: `Design.Line.hairline` (`layout.hairlineWidth`, `layout.hairlineOpacity`), `.focus` (the accent at 0.85).
- Scrim: `Design.Fill.scrim` 0.35 (the HIG's figure for a dimming layer under clear glass).
- **The accent** (owner, Q5) is a setting, `appearance.accent`: `system` (System Settings' accent, the default), `sunset` (Sunset's own tint),
  `neutral` (black / grey / white shades by scheme). Every accent use reads one token; later tinting options extend this setting.

### 3.6 Elevation and motion

- `Design.Shadow.popover` (black 0.25, radius 14, y 6), `.float` (black 0.3, radius 24, y 8).
- `Design.Motion.smooth` (`layout.animation`), `.hide` (`layout.hideDelay`).

## 4. Optical adjustments

A measure that the grid gets wrong to the eye (a symbol whose ink sits off its frame, a filled shape next to a hairline that looks larger
than the line) is corrected by a token in `Design.Optical`, each with:

- its name (what it corrects),
- its value,
- its reason and how it was measured (a screenshot, the ink's distance), in its documentation comment.

The two that exist today become the first: `GlyphSpacing.toText` (7: the glyph's ink as far from the text as from the edge, n63) and
`SidebarHeader.dockedButtonInset` (one hairline inside the card's edge). The enforcement test allows literals in `Design` only.

## 5. Components

| Component | What it fixes | Built on |
| --- | --- | --- |
| `Row` | glyph slot, title, detail, trailing accessory; the hover / pressed / selected fills | `ChoiceRowFill`, `GlyphSpacing` |
| `IconButton` | one square, one corner, the same fills | `SidebarIconButton` and its environment metrics |
| `Field` | leaf radius, control height + 2, the private and insecure variants | `AddressField` |
| `Bar` | `Size.bar`, `Space.s` inset, the surface, in a `GlassEffectContainer` | `WindowAddressBar` |
| `Panel` | header (title and close), content, footer; `Space.l` padding; a width token | `PermissionPanel`, `DownloadsList`, `HistoryPanel` |
| `Sheet` | title, message, content, buttons trailing; `Space.xxl` padding | `QuitSheet`, `ClearHistorySheet` |
| `SurfaceList` | rows in a floating surface, inset `Space.s`, gap `Space.hair` | `ChoiceList` |

## 6. Surfaces

Every surface is drawn as one of four kinds: **glass, material, opaque, transparent**, the values `window.material` already has. Owner (Q8):
this becomes one general choice for every surface, not only the window's background: the bars, panels, the floating sidebar, the tab
preview and the pane-area capsule all draw through one `Design.Surface` that reads it. Whether that is `window.material` itself or a new key
alongside it (e.g. the window opaque, its bars glass) is migration step 1's first question.

Glass groups: the address bar with its suggestions, the command bar with its actions panel, the find bar with its buttons, each in a
`GlassEffectContainer`.

## 7. Configuration

Today's `layout.*` keys stay the owner's to tune and are the source of the tokens they name; nothing else becomes a setting (Q7). New keys:
`appearance.accent`; the surface choice (§6); the pin button's two sizes as two named keys, docked and floating (Q6). `ShellSettings.Layout`
stops being a hand copy of `Configuration.Layout`: one list of fields describes both.

## 8. Enforcement

`DesignTokenTests`, beside `SourceStructureTests`: in the view files of SunsetShell, SunsetWeb and SunsetApp a numeric literal other than 0 is
an error inside `.padding(`, `spacing:`, `cornerRadius:`, `.opacity(`, `.shadow(`, `.font(.system(size:` and `RoundedRectangle(`, outside
`Design`. It holds a list of files still allowed; the list may only shrink. `.frame` is checked later (many frames are content sizes).

## 9. Not yet known

- The system's control measures on macOS 27 (a bordered button's radius, a rounded field's height per `ControlSize`): measured off-screen in
  step 1 before any token is said to match them.
- Variable blur on macOS (n60): a probe of the private `CAFilter` `variableBlur`, before 0028 step C.
