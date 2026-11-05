// Probe 2: (a) expand ASCII bytes into 8-byte cells, (b) find first differing 8-byte cell between two rows/grids.
#include <arm_neon.h>
#include <mach/mach_time.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static uint64_t now_ns(void) { static mach_timebase_info_data_t tb; if (!tb.denom) mach_timebase_info(&tb); return mach_absolute_time() * tb.numer / tb.denom; }
#define TIMED(label, bytes, CODE) do { double best = 1e18; for (int rep = 0; rep < 31; rep++) { uint64_t t0 = now_ns(); int it = 0; while (now_ns() - t0 < 2000000) { CODE; it++; } double per = (double)(now_ns() - t0) / it; if (per < best) best = per; } printf("  %-34s %8.2f ns/op  %7.2f GB/s\n", label, best, (double)(bytes) / best); } while (0)
#define SINK(p) __asm__ volatile("" :: "r"(p) : "memory")
typedef size_t (*dfn)(const uint64_t*, const uint64_t*, size_t);
typedef int (*efn)(const uint64_t*, const uint64_t*, size_t);

// (a) cell = template | codepoint << 2 (Ghostty-like: tag 2 bits, 21-bit codepoint, style id above)
__attribute__((noinline)) void expand_scalar(uint64_t *dst, const uint8_t *src, size_t n, uint64_t tmpl) { for (size_t i = 0; i < n; i++) dst[i] = tmpl | ((uint64_t)src[i] << 2); }
__attribute__((noinline)) void expand_neon(uint64_t *dst, const uint8_t *src, size_t n, uint64_t tmpl) {
    size_t i = 0; uint64x2_t t = vdupq_n_u64(tmpl);
    for (; i + 16 <= n; i += 16) {
        uint8x16_t v = vld1q_u8(src + i);
        uint16x8_t lo16 = vmovl_u8(vget_low_u8(v)), hi16 = vmovl_u8(vget_high_u8(v));
        uint32x4_t a = vmovl_u16(vget_low_u16(lo16)), b = vmovl_u16(vget_high_u16(lo16)), c = vmovl_u16(vget_low_u16(hi16)), d = vmovl_u16(vget_high_u16(hi16));
        uint32x4_t q[4] = {a, b, c, d};
        for (int k = 0; k < 4; k++) {
            uint64x2_t x0 = vshlq_n_u64(vmovl_u32(vget_low_u32(q[k])), 2), x1 = vshlq_n_u64(vmovl_u32(vget_high_u32(q[k])), 2);
            vst1q_u64(dst + i + k * 4, vorrq_u64(x0, t)); vst1q_u64(dst + i + k * 4 + 2, vorrq_u64(x1, t));
        }
    }
    for (; i < n; i++) dst[i] = tmpl | ((uint64_t)src[i] << 2);
}
// (b) first differing 8-byte cell
__attribute__((noinline)) size_t diff_scalar(const uint64_t *a, const uint64_t *b, size_t n) { size_t i = 0; while (i < n && a[i] == b[i]) i++; return i; }
__attribute__((noinline)) size_t diff_neon64(const uint64_t *a, const uint64_t *b, size_t n) {
    size_t i = 0;
    for (; i + 8 <= n; i += 8) {   // 64 bytes per step
        uint8x16_t x0 = veorq_u8(vld1q_u8((const uint8_t *)(a + i)), vld1q_u8((const uint8_t *)(b + i)));
        uint8x16_t x1 = veorq_u8(vld1q_u8((const uint8_t *)(a + i + 2)), vld1q_u8((const uint8_t *)(b + i + 2)));
        uint8x16_t x2 = veorq_u8(vld1q_u8((const uint8_t *)(a + i + 4)), vld1q_u8((const uint8_t *)(b + i + 4)));
        uint8x16_t x3 = veorq_u8(vld1q_u8((const uint8_t *)(a + i + 6)), vld1q_u8((const uint8_t *)(b + i + 6)));
        if (vmaxvq_u8(vorrq_u8(vorrq_u8(x0, x1), vorrq_u8(x2, x3))) != 0) break;
    }
    while (i < n && a[i] == b[i]) i++;
    return i;
}
__attribute__((noinline)) int eq_memcmp(const uint64_t *a, const uint64_t *b, size_t n) { return memcmp(a, b, n * 8) == 0; }

int main(void) {
    size_t N = 4096; uint8_t *src = malloc(N); uint64_t *dst = aligned_alloc(64, N * 8), *dst2 = aligned_alloc(64, N * 8);
    for (size_t i = 0; i < N; i++) src[i] = 0x20 + rand() % 95;
    expand_scalar(dst, src, N, 0x123ULL << 24); expand_neon(dst2, src, N, 0x123ULL << 24);
    if (memcmp(dst, dst2, N * 8)) { puts("MISMATCH expand"); return 1; }
    printf("(a) ASCII bytes -> 8-byte cells (input bytes/ns shown as GB/s of INPUT), %zu bytes in, %zu out\n", N, N * 8);
    TIMED("expand scalar (-Os)", N, expand_scalar(dst, src, N, 0x123ULL << 24); SINK(dst));
    TIMED("expand neon", N, expand_neon(dst2, src, N, 0x123ULL << 24); SINK(dst2));
    // row-sized (120 cols)
    TIMED("expand scalar, 120 cells", 120, expand_scalar(dst, src, 120, 0x123ULL << 24); SINK(dst));
    TIMED("expand neon,   120 cells", 120, expand_neon(dst2, src, 120, 0x123ULL << 24); SINK(dst2));

    printf("\n(b) first differing 8-byte cell; grids of 120x40 and 300x80 cells (GB/s of one grid compared)\n");
    size_t sizes[] = {120 * 40, 300 * 80, 120};
    const char *lab[] = {"120x40 grid", "300x80 grid", "one 120-cell row"};
    for (int s = 0; s < 3; s++) {
        size_t n = sizes[s]; uint64_t *a = aligned_alloc(64, n * 8), *b = aligned_alloc(64, n * 8);
        for (size_t i = 0; i < n; i++) a[i] = b[i] = ((uint64_t)rand() << 32) | (uint64_t)rand();
        size_t r1 = diff_scalar(a, b, n), r2 = diff_neon64(a, b, n); if (r1 != n || r2 != n) { puts("MISMATCH diff equal"); return 1; }
        b[n - 3] ^= 1; r1 = diff_scalar(a, b, n); r2 = diff_neon64(a, b, n); if (r1 != r2 || r1 != n - 3) { puts("MISMATCH diff"); return 1; } b[n - 3] ^= 1;
        printf(" %s (%zu bytes), identical:\n", lab[s], n * 8);
        { dfn volatile f = diff_scalar; TIMED("scalar word loop (-Os)", n * 8, __asm__ volatile("" ::: "memory"); size_t r = f(a, b, n); SINK(r)); }
        { dfn volatile f = diff_neon64; TIMED("neon 64B/step", n * 8, __asm__ volatile("" ::: "memory"); size_t r = f(a, b, n); SINK(r)); }
        { efn volatile f = eq_memcmp; TIMED("libc memcmp (equality only)", n * 8, __asm__ volatile("" ::: "memory"); int r = f(a, b, n); SINK(r)); }
        free(a); free(b);
    }
    return 0;
}
