---
status: proposed
date: 2026-11-05
---

# 0009 — Colour is a pipeline with a tested step at each stage

Input (palette, 256, truecolor, kitty wide-gamut) → working space → linear-light blending for text and alpha → display space (sRGB or Display P3; EDR later). Gamma- and contrast-aware text blending, minimum-contrast enforcement, theme and system-appearance following. Each conversion is tested against reference values, not by eye. Needs an `AemiColor` package (promotion, ADR-0002). Unmeasured: how kitty and macOS font smoothing treat text gamma; to be measured with screenshots under controlled backgrounds.

## Owner steer (note n10, 2026-11-06) and first evidence

"Colour accuracy and matching of the screen profile the window is on is very critical." So the last stage of the pipeline is measured on a real window, not argued.

- **Stage "display" in the app today:** the CPU renderer works in sRGB values (the palette, the 256 colours and truecolor are all read as sRGB); the frame is tagged sRGB (`CGColorSpace.sRGB`) and the window server converts to the profile of the screen the window is on (and again when the window moves to another screen). The tag is the one that matters: tagging the frame with the window's own colour space is cheaper (no conversion pass; it removed vImage from the idle profile) but shows the numbers as raw display values.
- **Probe** (`Scripts/colour-probe/run.sh`, local, needs a GUI session): the app shows eight stripes of known sRGB colours; a screenshot of the window (which carries the display's profile) is converted back to sRGB and compared. Built-in Liquid Retina display, profile Display P3, 2026-11-06: tagged sRGB, worst channel error 3 of 255 (green 0,255,0 shown as 3,255,0; the rest 0-1). **Negative control:** with the frame tagged by the window's colour space the same probe reads errors of 26 (255,128,64 shown as 255,119,38), 19 and 13, so the probe does tell the two apart.
- **Not established:** a second display with another profile (only one is attached), moving a window between screens, a profile that is not P3 or sRGB, HDR/EDR. The probe measures flat fills; glyph edges are blended on the CPU in gamma-encoded sRGB (not linear light), which is not measured and is the next accuracy question for text. The ADR stays proposed until the rest of the pipeline (working space, blending, contrast) has its own tests.
