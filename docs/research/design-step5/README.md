# Design step 5: every view on the tokens (2026-11-12)

Every view file of SunsetShell, SunsetWeb and SunsetApp now names its paddings, gaps, radii, opacities, shadows and font sizes:
`DesignTokenAllowance` is empty.

## Values moved up to the scale (the owner decides which were optical)

`off-scale-in-app.png`: today on the left, on the scale on the right, from the app (axdrive, background).

| # | Where | Today | Now | Shown |
| --- | --- | --- | --- | --- |
| 1 | Built-in tab bar: a tab's horizontal padding | 10 | 12 | yes (1) |
| 1 | Built-in tab bar: the separator's inset | 3 | 4 | yes (1) |
| 2 | Kind chooser (New Tab of Kind…): gaps | 10 | 12 | yes (2) |
| 3 | Clear History: gap between groups | 14 | 16 | yes (3) |
| 3 | Clear History: the options' indent | 20 | 24 | yes (3) |
| 4 | A row's title to its second line | 1 | 2 | yes (4) |
| 4 | Not Secure mark and site button: symbol to text | 3 | 4 | partly (the lock in the field) |
| 5 | History row: title to address | 1 | 2 | no (History panel is rebuilt in 0028 B) |
| 5 | History panel: header padding | 10 | 12 | no (same) |
| 6 | Command sheet (Edit Command…), download card, empty page: gaps | 10 | 12 | no |
| 7 | Pane-area label ("Shown in another window"): padding | 10 / 5 | 12 / 6 | no (needs a second window) |

## Kept as they were, named (not on the grid on purpose)

- `Design.System.lightsPitch` 23 (AppKit's traffic lights), `lightsClearance` 72 (the lights' room for the built-in bar),
  `commandBarTop` 56 (under the title bar).
- `Design.Optical.siteRowsIndent` 26 (Settings > Websites, the per-site rows under the site's name): **to confirm**, not measured.
- `Design.Optical.thumbnailSymbol` 0.5 (a file's symbol at half its thumbnail), `Design.Line.*` (hairline factors).
- Radii: the split sub-row's corner is now concentric (`ConcentricRadius.inner(outer: tabRadius, inset: 2)`, 4 as before); the
  initial glyph's 3.5 is the small radius (4); the icon popover's 5 is the leaf (6).

## Not done yet in this step

- Roadmap 0028 B (the history panel on the sidebar's parts), and frames in the enforcement test: after the owner's call on the values above.

## The owner's answers (2026-11-12)

- All the values moved up stay on the scale (no optical exceptions).
- The built-in tab bar "does not look native nor close to the design language of the sidebar": to be redrawn with the sidebar's parts.
- In the tab bar, the close button replaces the tab's icon under the pointer.

## The built-in tab bar, redrawn (2026-11-12)

`tab-bar.png`: before / after. Each tab is a sidebar row (`BarTab`): the open fill, the selected fill and hairline, the leaf corner, 32 pt;
the tabs share the bar's width (120–240 pt each); the bar has no material of its own; the + is the bar's icon button. The close button
takes the icon's place under the pointer (not shown: the driver does not move the pointer).

Owner's further asks, same day (not built yet):
- Variable blur under the tabs (n60, t208), at least as an option.
- In tab-bar mode the address field is not a separate row: each tab is its own address slot (the selected tab is the field).
