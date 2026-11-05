---
status: rejected
superseded-by: 0021
date: 2026-11-05
---

# 0015 — The screen's cell memory is the GPU's vertex data (unified-memory Macs)

## Context

Ghostty builds a 32-byte instance per glyph and a 4-byte background per cell on the CPU; Alacritty batches per frame; kitty uploads its 20-byte `GPUCell` array.

## Proposal (a research bet, not a decision)

Page-aligned `mmap` screen pages wrapped as Metal buffers (`makeBuffer(bytesNoCopy:)`); the shader reads 8-byte cells and maps codepoint → atlas slot through a table; rows needing shaping (ligatures, emoji sequences, text sizing) use a small side buffer built by the CPU. Active screen triple-buffered; cold pages immutable.

## Open

Micro-benchmark first: CPU-rebuilt instances vs direct cell reads at 120×40 and 300×80, frame CPU and GPU time. Risks: writer/GPU consistency, the shaping side channel, `bytesNoCopy` behaviour with decommitted pages. Reject if the win is not material.

**Result (2026-11-05, probe T0.5):** not pursued; see ADR-0021.
