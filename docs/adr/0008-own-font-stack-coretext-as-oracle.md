---
status: proposed
date: 2026-11-05
---

# 0008 — Our own font stack (parsing, shaping, rasterising); CoreText as the macOS oracle

Linux has no CoreText, and 'only our own tooling' excludes HarfBuzz and FreeType, so OpenType parsing (`cmap`, `glyf`/CFF, GSUB/GPOS, variable fonts, COLR/CPAL, sbix/CBDT), shaping, fallback and glyph rasterising are ours (a promoted Aemi package, shared with Mermaid's text metrics). On macOS we may use CoreText early for parity and as the oracle our output is compared against glyph by glyph; whether CoreText stays a production backend is decided later. Multi-month; the owner accepts that.
