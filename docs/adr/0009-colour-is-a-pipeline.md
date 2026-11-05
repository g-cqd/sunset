---
status: proposed
date: 2026-11-05
---

# 0009 — Colour is a pipeline with a tested step at each stage

Input (palette, 256, truecolor, kitty wide-gamut) → working space → linear-light blending for text and alpha → display space (sRGB or Display P3; EDR later). Gamma- and contrast-aware text blending, minimum-contrast enforcement, theme and system-appearance following. Each conversion is tested against reference values, not by eye. Needs an `AemiColor` package (promotion, ADR-0002). Unmeasured: how kitty and macOS font smoothing treat text gamma; to be measured with screenshots under controlled backgrounds.
