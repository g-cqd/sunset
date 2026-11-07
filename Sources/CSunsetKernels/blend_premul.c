#include "csunset_kernels.h"

#if defined(__ARM_NEON)
#include <arm_neon.h>
#endif

/// One pixel: every channel, alpha included, with the text colour opaque.
static inline uint32_t blend_pixel_premul(uint32_t below, uint32_t alpha, uint32_t r, uint32_t g, uint32_t b) {
    uint32_t inverse = 255 - alpha;
    uint32_t red = (r * alpha + (below & 0xFF) * inverse + 127) / 255;
    uint32_t green = (g * alpha + ((below >> 8) & 0xFF) * inverse + 127) / 255;
    uint32_t blue = (b * alpha + ((below >> 16) & 0xFF) * inverse + 127) / 255;
    uint32_t out = (255 * alpha + (below >> 24) * inverse + 127) / 255;
    return (out << 24) | (blue << 16) | (green << 8) | red;
}

void sunset_blend_coverage_premul_scalar(uint32_t *destination, const uint8_t *coverage, size_t count, uint32_t color) {
    uint32_t r = color & 0xFF, g = (color >> 8) & 0xFF, b = (color >> 16) & 0xFF;
    for (size_t i = 0; i < count; i++) {
        uint32_t alpha = coverage[i];
        if (alpha != 0) destination[i] = blend_pixel_premul(destination[i], alpha, r, g, b);
    }
}

#if defined(__ARM_NEON)
/// Exactly t / 255 for t = x + 127 with x at most 65025: (t + 1 + (t >> 8)) >> 8.
static inline uint8x8_t div255_premul(uint16x8_t x) {
    uint16x8_t t = vaddq_u16(x, vdupq_n_u16(127));
    uint16x8_t u = vaddq_u16(vaddq_u16(t, vdupq_n_u16(1)), vshrq_n_u16(t, 8));
    return vshrn_n_u16(u, 8);
}

static inline void blend8_premul(uint32_t *destination, uint8x8_t alpha, uint8x8_t cr, uint8x8_t cg, uint8x8_t cb) {
    uint8x8x4_t pixel = vld4_u8((const uint8_t *)destination);
    uint8x8_t inverse = vsub_u8(vdup_n_u8(255), alpha);
    uint8x8x4_t out;
    out.val[0] = div255_premul(vaddq_u16(vmull_u8(cr, alpha), vmull_u8(pixel.val[0], inverse)));
    out.val[1] = div255_premul(vaddq_u16(vmull_u8(cg, alpha), vmull_u8(pixel.val[1], inverse)));
    out.val[2] = div255_premul(vaddq_u16(vmull_u8(cb, alpha), vmull_u8(pixel.val[2], inverse)));
    // The alpha lane takes the same formula with the colour's alpha, 255: 255 * a + da * (255 - a).
    out.val[3] = div255_premul(vaddq_u16(vmull_u8(vdup_n_u8(255), alpha), vmull_u8(pixel.val[3], inverse)));
    vst4_u8((uint8_t *)destination, out);
}

void sunset_blend_coverage_premul(uint32_t *destination, const uint8_t *coverage, size_t count, uint32_t color) {
    uint8x8_t cr = vdup_n_u8((uint8_t)(color & 0xFF));
    uint8x8_t cg = vdup_n_u8((uint8_t)((color >> 8) & 0xFF));
    uint8x8_t cb = vdup_n_u8((uint8_t)((color >> 16) & 0xFF));
    size_t i = 0;
    for (; i + 8 <= count; i += 8) {
        uint8x8_t alpha = vld1_u8(coverage + i);
        if (vmaxv_u8(alpha) == 0) continue;
        blend8_premul(destination + i, alpha, cr, cg, cb);
    }
    size_t rest = count - i;
    if (rest != 0) {
        // The tail on a padded copy: coverage 0 in the padding leaves it alone (also its alpha: da * 255 / 255 = da).
        uint8_t padded_coverage[8] = {0, 0, 0, 0, 0, 0, 0, 0};
        uint32_t padded[8] = {0, 0, 0, 0, 0, 0, 0, 0};
        for (size_t k = 0; k < rest; k++) { padded_coverage[k] = coverage[i + k]; padded[k] = destination[i + k]; }
        uint8x8_t alpha = vld1_u8(padded_coverage);
        if (vmaxv_u8(alpha) != 0) {
            blend8_premul(padded, alpha, cr, cg, cb);
            for (size_t k = 0; k < rest; k++) destination[i + k] = padded[k];
        }
    }
}
#else
void sunset_blend_coverage_premul(uint32_t *destination, const uint8_t *coverage, size_t count, uint32_t color) {
    sunset_blend_coverage_premul_scalar(destination, coverage, count, color);
}
#endif
