#include "csunset_kernels.h"

#if defined(__ARM_NEON)
#include <arm_neon.h>
#endif

/// One pixel, the definition: per channel (c * a + d * (255 - a) + 127) / 255, the result opaque; coverage 0 leaves the pixel alone.
static inline uint32_t blend_pixel(uint32_t below, uint32_t alpha, uint32_t r, uint32_t g, uint32_t b) {
    uint32_t inverse = 255 - alpha;
    uint32_t red = (r * alpha + (below & 0xFF) * inverse + 127) / 255;
    uint32_t green = (g * alpha + ((below >> 8) & 0xFF) * inverse + 127) / 255;
    uint32_t blue = (b * alpha + ((below >> 16) & 0xFF) * inverse + 127) / 255;
    return 0xFF000000u | (blue << 16) | (green << 8) | red;
}

void sunset_blend_coverage_scalar(uint32_t *destination, const uint8_t *coverage, size_t count, uint32_t color) {
    uint32_t r = color & 0xFF, g = (color >> 8) & 0xFF, b = (color >> 16) & 0xFF;
    for (size_t i = 0; i < count; i++) {
        uint32_t alpha = coverage[i];
        if (alpha != 0) destination[i] = blend_pixel(destination[i], alpha, r, g, b);
    }
}

#if defined(__ARM_NEON)
/// Exactly t / 255 for t in 0...65535 (t = x + 127 with x at most 65025): (t + 1 + (t >> 8)) >> 8.
static inline uint8x8_t div255(uint16x8_t x) {
    uint16x8_t t = vaddq_u16(x, vdupq_n_u16(127));
    uint16x8_t u = vaddq_u16(vaddq_u16(t, vdupq_n_u16(1)), vshrq_n_u16(t, 8));
    return vshrn_n_u16(u, 8);
}

/// Eight pixels: the vector step shared by the main loop and the tail.
static inline void blend8(uint32_t *destination, uint8x8_t alpha, uint8x8_t cr, uint8x8_t cg, uint8x8_t cb) {
    uint8x8x4_t pixel = vld4_u8((const uint8_t *)destination);
    uint8x8_t inverse = vsub_u8(vdup_n_u8(255), alpha);
    uint8x8x4_t out;
    out.val[0] = div255(vaddq_u16(vmull_u8(cr, alpha), vmull_u8(pixel.val[0], inverse)));
    out.val[1] = div255(vaddq_u16(vmull_u8(cg, alpha), vmull_u8(pixel.val[1], inverse)));
    out.val[2] = div255(vaddq_u16(vmull_u8(cb, alpha), vmull_u8(pixel.val[2], inverse)));
    // Coverage 0 gives back the destination channel exactly ((d * 255 + 127) / 255 = d), and the destination is opaque.
    out.val[3] = vdup_n_u8(255);
    vst4_u8((uint8_t *)destination, out);
}

void sunset_blend_coverage(uint32_t *destination, const uint8_t *coverage, size_t count, uint32_t color) {
    uint8x8_t cr = vdup_n_u8((uint8_t)(color & 0xFF));
    uint8x8_t cg = vdup_n_u8((uint8_t)((color >> 8) & 0xFF));
    uint8x8_t cb = vdup_n_u8((uint8_t)((color >> 16) & 0xFF));
    size_t i = 0;
    for (; i + 8 <= count; i += 8) {
        uint8x8_t alpha = vld1_u8(coverage + i);
        // Most of a glyph's rows are empty at the edges: eight empty coverages leave the pixels as they are.
        if (vmaxv_u8(alpha) == 0) continue;
        blend8(destination + i, alpha, cr, cg, cb);
    }
    size_t rest = count - i;
    if (rest != 0) {
        // The last one to seven pixels (a glyph row is rarely a multiple of eight wide: done one at a time they were most of the cost): the same vector
        // step on a padded copy, with coverage 0 (no change) in the padding, and only the real pixels copied back.
        uint8_t padded_coverage[8] = {0, 0, 0, 0, 0, 0, 0, 0};
        uint32_t padded[8] = {0xFF000000u, 0xFF000000u, 0xFF000000u, 0xFF000000u, 0xFF000000u, 0xFF000000u, 0xFF000000u, 0xFF000000u};
        for (size_t k = 0; k < rest; k++) { padded_coverage[k] = coverage[i + k]; padded[k] = destination[i + k]; }
        uint8x8_t alpha = vld1_u8(padded_coverage);
        if (vmaxv_u8(alpha) != 0) {
            blend8(padded, alpha, cr, cg, cb);
            for (size_t k = 0; k < rest; k++) destination[i + k] = padded[k];
        }
    }
}
#else
void sunset_blend_coverage(uint32_t *destination, const uint8_t *coverage, size_t count, uint32_t color) {
    sunset_blend_coverage_scalar(destination, coverage, count, color);
}
#endif
