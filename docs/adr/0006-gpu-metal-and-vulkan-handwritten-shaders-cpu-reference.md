---
status: proposed
date: 2026-11-05
---

# 0006 — Metal and Vulkan, hand-written shaders, and a CPU reference renderer

A glyph atlas and instanced cell quads as kitty and Ghostty do (kitty's shaders are cell, graphics, border, trail … in Slang, read as file names). Metal on macOS (`CAMetalLayer`, display-link pacing); Vulkan on Linux (GL fallback is an open question, unprobed). Shaders: a small set written by hand in MSL and GLSL/SPIR-V (about ten), so there is no build-time cross-compiler dependency; a CPU renderer is the reference for pixel tests and the fallback on device loss. Open: the shader strategy, if the set grows.

**Owner direction (2026-11-05):** Vulkan is, if anything, for Linux and is a much later stage. Metal and the CPU reference come first; the Linux renderer is decided when Linux work reaches the renderer (roadmap 0013), after the core and host run there.
