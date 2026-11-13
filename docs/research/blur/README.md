---
status: for the owner's reading
date: 2026-11-12
asked-in: design step 5, the owner's notes on variable blur (n60, t208) and AemiSDR
---

# Blur for the bars: variable blur and tuned backdrop blur, in AemiSDR first

Nothing is built. The probe below ran in a throw-away copy of Sunset (`/tmp`, never committed), driven in the background.

## 1. What was measured

`probe-2026-11-12.png`: a test page (colour bands, sharp text, swatches) under a 76 pt strip at the top of the pane area, macOS 27.0.1.

| Variant | How | Seen |
| --- | --- | --- |
| none | nothing | the page as it is |
| gaussian | `CABackdropLayer` + `gaussianBlur` 24 | an even blur ending in a hard line |
| gaussian-tuned | + `colorSaturate` 1.8, `colorBrightness` -0.08 | the same, livelier colour (what AemiSDR's Backdrop Blur tunes) |
| faded | gaussian, the layer's opacity masked by a gradient | the blur fades, but sharp page shows through it at half: a double image |
| faded-tuned | faded + the tuning | the same, with livelier colour |
| variable | `variableBlur` 24, a mask image: full over the top half, falling to 0 over the bottom half | the blur radius itself falls to nothing: no line, no double image |
| variable-tuned | variable + the tuning | the same, livelier |

Findings:
- `CAFilter.filterTypes` lists `variableBlur` on macOS 27 (inputs: `inputMaskImage`, `inputRadius`, `inputNormalizeEdges`, `inputFade`,
  `inputDither`, …); `CABackdropLayer` exists. AemiSDR's variable blur is iOS-only today only because it hangs the filter on a
  `UIVisualEffectView`; the filter itself is there on macOS.
- **Variable is the only clean fade.** Masking the opacity of a uniform blur (faded) is cheaper but shows the sharp page through.
- A light halo at the very bottom of the variable strip comes from `inputNormalizeEdges` meeting a white page; to tune (`inputFade`,
  normalize off) in the real build.
- Not measured: cost (frame time while scrolling a page under it), behaviour across Spaces and full screen, iOS.

## 2. Two blurs, what each is for

| | Backdrop blur (tuned) | Variable blur |
| --- | --- | --- |
| What | one radius, plus saturation, brightness, tint, darkening, zoom (AemiSDR's `BackdropBlurConfiguration`) | a radius that changes across the area, from a mask |
| Where it fits | a surface with an edge: a panel, a popover, the floating sidebar, the command bar's backdrop | an edge with no surface: under a bar, at the ends of a scrolling list |
| Reads | what is under it in the window (`CABackdropLayer`), or behind the window (`NSVisualEffectView`) | what is under it in the window |
| Cost | one blur pass | one blur pass with a per-pixel radius; the mask is made once per size |

They combine: the tuning filters (saturate, brightness) run after either blur, in the same filter list.

## 3. The plan in AemiSDR (iOS and macOS)

One core both platforms share, and thin views on each:

```
AemiSDR
  Effects/Blur/
    BlurRecipe.swift            value: kind (.uniform(radius) | .variable(radius, mask)), tuning (saturation, brightness,
                                tint, darkening), captureScale. Sendable, Equatable.
    BlurMask.swift              value: the shapes MaskType has today (linear edges, rounded rect, superellipse) + .edge(Edge,
                                solid: Double, fade: Double) for "full over the bar, fading over a bar's height"; cached CGImage
                                by (mask, pixel size, inverted).
    BackdropFilterStack.swift   builds the CAFilter list for a recipe through Abysm (typed): RuntimeClass("CAFilter"),
                                method "filterWithType:" as (String) -> NSObject?, properties set with RuntimeObject.write
                                (throws, never crashes on a missing key). Names in _InternedKeys (#Interned).
    BlurLayer.swift             a CABackdropLayer (or nil) with the stack installed; `apply(_ recipe:)` diffs and only touches
                                what changed; groupName, windowServerAware, scale. Main actor.
  Platform/
    BlurNSView.swift   (macOS)  NSView hosting BlurLayer; layout updates the mask size off the main thread, applied on main.
    BlurUIView.swift   (iOS)    the same on UIView (today's VariableBlurUIView keeps its API and moves onto the core).
  SwiftUI/
    View+Blur.swift             .backdropBlur(_ recipe:, in shape:) and .variableBlur(edge:, solid:, fade:, radius:) on both.
```

Safety and performance, both platforms:
- **Every private name** is an `#Interned` key and every call goes through Abysm (`RuntimeClass`, typed `method(…, as:)`,
  `RuntimeObject.write`), so a signature or key that changes between OS releases throws and is logged once, never crashes.
- **Fallback chain**, decided once per process: variable → uniform backdrop blur → the system material (`NSVisualEffectView` /
  `UIVisualEffectView`) → nothing. `RuntimeAccess.isEnabled = false` (a kill switch) goes straight to the material.
- **No filter work during SwiftUI layout** (AemiSDR found the crash on macOS 26: modifying the layer tree inside `updateNSView`):
  changes are applied on the next main-actor turn (`Task { @MainActor }`, not `DispatchQueue`), coalesced.
- **Masks** made off the main thread, cached by size; the filter keeps its previous mask until the new one is ready (no black frame).
- **Reduce Transparency** (accessibility) turns every blur into the opaque raised colour.
- Tests: recipe → filter-list unit tests (no window); a snapshot test per platform behind an environment flag; an Abysm resolution
  test that fails when a private name stops resolving on a new OS.
- Sunset then depends on AemiSDR (pinned revision); its own `SunsetPrivate/BackdropBlur` is replaced.

## 4. Where Sunset would use them (variants)

Setting: `appearance.barBlur`: `variable` (default) / `surface` (the bars draw as today's surface kind) / `none`.

| Place | Variant A (proposed) | Variant B | Variant C |
| --- | --- | --- | --- |
| Built-in tab bar | variable: full under the bar, fading over 38 pt below it; no fill | variable + tuning (saturate 1.8) | today's surface (glass etc.) |
| Window address bar (when out) | variable under it, the bar's own surface kept (glass on blur) | variable only, the bar drawn as icons and a field on the blur | surface only |
| Find bar | uniform tuned backdrop blur in its rounded shape (it is a panel) | variable band across the pane's top | surface only |
| Command bar backdrop | uniform blur of the whole window behind it (radius 8, darkened 0.18) instead of today's black at 0.18 | darkening only (today) | |
| Sidebar list ends | variable at the top (under the pin) and bottom (under the + bar), 24 pt each, as the list scrolls under them | an alpha fade of the rows instead of blur (AemiSDR's Alpha Mask) | nothing (today) |
| Floating sidebar, panels, popovers | tuned backdrop blur as a fifth surface kind (`window.material: blur`) | | |

## 5. Questions before building

1. The plan in §3 (the shared core, Abysm, the fallback chain) — or changes.
2. For each place in §4: A, B or C.
3. Whether the old AemiSDR iOS API (`VariableBlurView`, `BackdropBlurView`) may change (a major version), or must stay source-compatible.

## 6. Built (2026-11-12): the owner's "go" read as the plan in §3, variant A everywhere, AemiSDR's iOS API kept

AemiSDR (pushed, e1c50bd): roadmap 0020 slices 1–3, ADR-0009, diary 2026-11-12-01. 18 new tests; an iOS simulator build succeeds.
Found by its tests: `+[CAFilter filterWithType:]` returns an object for a made-up type, so types are checked against `+filterTypes`.

Sunset: the family's repin (aemi 0bae2ed, TerminalKit 7913fe6, AemiJSON 806b481) and AemiSDR e1c50bd; `appearance.barBlur`
(variable / surface / none, 111 keys); `Design.Blur`; `.blurUnder(_:solid:fade:)` under the window's address bar and at both ends of
the sidebar's list; `.blurSurface` for the find bar; `CommandBarBackdrop` behind the command bar.

`built-2026-11-12.png`, in the app (background): the find bar (surface / tuned blur), the command bar's backdrop (dark veil / soft
dark blur), the sidebar's ends (fade only / fade and blur).

Not done or not seen:
- The built-in tab bar's blur and the address in its tabs: next (they change the bar together).
- The window's address bar with its blur (it comes out on hover only).
- The top of the sidebar list blurring (needs the list scrolled under the pin; the driver does not scroll).
- iOS: AemiSDR's `VariableBlurUIView` is not on the new core yet (its slice 4); the canary has not run on an iOS simulator.
- No cost measured (AemiSDR slice 5).

## 7. Edges (2026-11-13): "when there is blur we should avoid clipping on sections"

Tested over a page of stripes, text and tables (`/tmp/permsrv/article.html`), not plain colours or soft gradients: a blur only
shows over a pattern. `edges-2026-11-13.png`:

- Under the address bar the stripes stopped on a line. Two causes in AemiSDR (diary 2026-11-13-01, 71e629d): the mask was never
  fitted (filters assigned while the SwiftUI layer was 0×0, so the band blurred at full strength to its edge), and a straight fall
  hides content until its last points. Now the filters are assigned again on resize, and the fall is cubic.
- At the ends of the sidebar's list the band ended where the pin's strip and the + bar end. It now reaches `Design.Blur.listOverhang`
  past them, over the first row at rest, so nothing marks where it stops (`TabSidebar.listEndBlur`).
- The bands no longer share a backdrop group: a shared capture showed one band's content in another.
- Still clipped to their shapes, on purpose: the find bar's blur (a panel's surface) and the cards' content.

`command-variants-2026-11-13.png`: the command bar's backdrop, (1) the dark veil without blur, (2) the built one (blur 8, darker),
(3) soft focus (blur 3), (4) frosted (blur 18, livelier colour). The owner chose (3).

axdrive learned `scroll PID X Y DY` and `hover PID X Y` (events posted to the process, nothing brought to the front); History has
Open Address (the window's bar comes out for it), which the scene uses.

### 7b. Owner, 2026-11-13: a longer fall, a darker bar, no sides in the sidebar, panes above (`edges2-2026-11-13.png`)

- The blur under the window's address bar falls over two bars' heights below it (`Design.Blur.barFall`).
- The bar itself has a black shade under its surface (`Design.Fill.barShade` 0.3), for its text over a light page.
- The sidebar's bands reach `margin + Design.Blur.listBleed` past both sides; the panes draw above the sidebar (`zIndex(1)`), so
  the bleed shows only in the sidebar and the gap, and the window's edge ends it on the other side.
- Not seen: the bar at the bottom edge, the floating sidebar (its panel still clips to its shape), light appearance.

### 7c. Owner, 2026-11-13: the address bar's blur, smaller

- The fall starts half way down the bar (`Design.Blur.barSolid`), not after it.
- Radius 8 (was 24).
- A third less tall: 87 pt from the window's edge (`Design.Blur.barKeep` 0.67; `heights-2026-11-13.png` shows 130 / 98 / 87).
- Cut to the focused pane's card (`PaneCardShape`, published by the pane area): in a split it does not reach the other pane, the gaps
  or the sidebar.

### 7d. Owner, 2026-11-13: the command bar over the panes, the address bar above its backdrop, the find bar's blur

- The command bar is centred over the pane area, not the window (`PaneCardShape.Area`, an anchor the pane area publishes); its
  backdrop is drawn by `WindowDialogs` under the window's address bar, which stays sharp while the command bar is open
  (`command-centred-2026-11-13.png`: one pane, then a split).
- The find bar: a halo all around (AemiSDR `BlurMask.around`) was rejected; then two fall lengths (`halo-variants-2026-11-13.png`,
  the owner chose A: from 12 pt inside the panel to 16 pt outside), and the blur reaching the pane's corner on the panel's two near
  sides (AemiSDR `BlurMask.corner`, 88d2b80; `BlurHalo`; `find-corner-2026-11-13.png`). The panel has the address bar's dark shade.
- Not seen: the find bar in a split's other pane, light appearance, scrolling.

### 7e. Owner, 2026-11-13: the system toolbar's way (`groups-2026-11-13.png`)

"Radii not concentric to the panes' corners", "the address bar so wide compared to the command bar": replaced by glass groups.
- `View.barGroup(margin:top:)`: regular glass in a `ConcentricRectangle` (the card declares `containerShape`), and under it its own
  variable blur (AemiSDR `BlurMask.under`, 220ec84): full from the card's edge to half way down the group, falling below it and at
  both ends, 16 pt past them.
- The window's address bar: back/forward/reload in one group at the leading edge, the address in another, as wide as the command bar
  at most, centred in the rest; laid over the focused pane's card and cut to it.
- The find bar: one group, in the card's top-trailing corner. The command bar: regular glass.
- Removed: the halo (`BlurHalo`, `blurSurface`) and the bar's dark shade (the glass carries the contrast now).
- Chosen without the owner (no answer): two groups (nav, address), one blur per group with sharp gaps between them.
- Not seen: light appearance, the bar at the bottom, scrolling, cost.

### 7f. Owner, 2026-11-13: contrast and capsules

- A tint on the glass (`.regular.tint`) changed nothing visible; a black fill inside the glass shape does
  (`contrast-2026-11-13.png`, 0.3 / 0.5): the owner chose 0.5 (`Design.Fill.barShade`). Groups and the command bar draw their
  controls dark-scheme.
- The groups are capsules, as the system's toolbar groups; their fields and buttons too (`\.controlRadius`, half the field's height),
  concentric with the group at the container inset (`capsules-2026-11-13.png`).

### 7g. Split mode (t225; `split-margin-2026-11-13.png`)

- `web.splitBar` (margin / pane, 112 keys). Margin (default): while the window bar is out in a split, a margin of `Space.m + Size.bar`
  opens above the panes and the bar sits in it, across the pane area, with no blur (it is over no page). The top cards start lower
  and are cut shorter; their content keeps its size and place (the test page did not get a resize event). Pane: the bar floats over
  the focused pane, as before.
- Only with the bar at the top edge; at the bottom it stays over the pane.
- Not seen: terminals in the split (their view is cut the same way, not re-laid out), the animation as the margin opens.

### 7h. Owner, 2026-11-13: lighter group blur, one row with find, the split margin's gap

- The group blur was too strong. Radius 8 → 4/3/2 (`group-radius-…`), then 2 with the area grown (`group-area-…`, chosen E: full to
  the group's bottom edge, fall and reach +24), then radius 1 with more reach (`group-reach-…`, chosen R48). Now
  `Design.Blur.groupRadius` 1, solid `margin + Size.bar`, `groupFall` `Size.bar + Space.xxl`, `groupReach` `Space.xl + 3·Space.xxl`
  (88 pt). The whole-bar blur (`barRadius` 8) is unchanged.
- Groups in one row draw their blurs beneath all of them (`View.barGroupBlurs()`; each group publishes an anchor): no group's blur falls
  over another's glass, which the 88 pt reach would otherwise do.
- The find bar has the window bar's look: a field group (options, text, count, in a capsule field) and a buttons group (up, down, ×).
  At the top, over the focused pane, the window bar's row hosts it at its trailing end: alone while the address bar is in, the
  address shifting beside it when it comes out (opening find does not bring the address bar). In the split margin the find bar stays in
  its pane (`find-row-…`).
- Split margin: the bar was `Space.m` from the area's top while the panes were the split gap from it; it now uses the split gap all
  round, so it sits where the panes' tops were and the gap under it is the gap between panes.
- Not seen: the bar at the bottom edge with find open (find stays in its pane there), light appearance, find with the sidebar address.
