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

/// The number of leading elements that matter: one more than the index of the last non-zero element, 0 when all are zero. Screen cells are 64-bit words
/// and a blank cell in the default style is 0, so this is the length of a row without its trailing blanks.
size_t sunset_used_length_u64(const uint64_t *cells, size_t count);

/// The same, one element at a time: the reference.
size_t sunset_used_length_u64_scalar(const uint64_t *cells, size_t count);

/// The same blend over a *premultiplied* destination of any alpha: every channel, alpha included, is (c * a + d * (255 - a) + 127) / 255 with the colour opaque,
/// so a pixel that was transparent becomes partly opaque and an opaque one stays opaque. Coverage 0 leaves a pixel as it is.
void sunset_blend_coverage_premul(uint32_t *destination, const uint8_t *coverage, size_t count, uint32_t color);
void sunset_blend_coverage_premul_scalar(uint32_t *destination, const uint8_t *coverage, size_t count, uint32_t color);

#endif
