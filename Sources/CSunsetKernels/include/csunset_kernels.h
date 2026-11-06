#ifndef CSUNSET_KERNELS_H
#define CSUNSET_KERNELS_H

#include <stddef.h>
#include <stdint.h>

/// Blends a color over `count` opaque RGBA pixels (bytes R, G, B, A; as a little-endian word 0xAABBGGRR) with the glyph coverage `coverage[i]` (0...255) as the
/// alpha of each: out = (color * a + dst * (255 - a) + 127) / 255 per channel, exactly (integer division). Coverage 0 leaves the pixel as it is; the result
/// is opaque. `color` is packed like a pixel (alpha ignored). The destination must be opaque.
void sunset_blend_coverage(uint32_t *destination, const uint8_t *coverage, size_t count, uint32_t color);

/// The same, one pixel at a time and without vector instructions: the reference the vector kernel is tested against, and the fallback.
void sunset_blend_coverage_scalar(uint32_t *destination, const uint8_t *coverage, size_t count, uint32_t color);

#endif
