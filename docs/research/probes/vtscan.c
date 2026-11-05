// Probe: how fast can a VT parser's "stage 1" find control bytes? (Sunset research, not shipped code)
// Variants: scalar loop; repeated Aemi adf_index_of_control_or_any5; bulk NEON positions (simdjson-style stage 1).
#include <arm_neon.h>
#include <mach/mach_time.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "CAemiKernels.h"

static uint64_t now_ns(void) { static mach_timebase_info_data_t tb; if (!tb.denom) mach_timebase_info(&tb); return mach_absolute_time() * tb.numer / tb.denom; }
static inline int is_ctl(uint8_t b) { return b < 0x20 || b == 0x7F; }

// scalar reference: positions of every control byte
__attribute__((noinline)) size_t pos_scalar(const uint8_t *p, size_t n, uint32_t *out) {
    size_t k = 0; for (size_t i = 0; i < n; i++) if (is_ctl(p[i])) out[k++] = (uint32_t)i; return k;
}
// repeated Aemi kernel (dispatcher per call)
__attribute__((noinline)) size_t pos_aemi_repeat(const uint8_t *p, size_t n, uint32_t *out) {
    size_t k = 0, i = 0;
    while (i < n) {
        size_t j = adf_index_of_control_or_any5(p + i, n - i, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F);
        if (i + j >= n) break;
        out[k++] = (uint32_t)(i + j); i += j + 1;
    }
    return k;
}
// bulk NEON stage 1: 16 bytes per step, nibble masks, positions out
__attribute__((noinline)) size_t pos_neon_bulk(const uint8_t *p, size_t n, uint32_t *out) {
    size_t k = 0, i = 0;
    const uint8x16_t c20 = vdupq_n_u8(0x20), c7f = vdupq_n_u8(0x7F);
    for (; i + 16 <= n; i += 16) {
        uint8x16_t v = vld1q_u8(p + i);
        uint8x16_t m = vorrq_u8(vcltq_u8(v, c20), vceqq_u8(v, c7f));
        uint64_t mask = vget_lane_u64(vreinterpret_u64_u8(vshrn_n_u16(vreinterpretq_u16_u8(m), 4)), 0);
        mask &= 0x8888888888888888ULL;
        while (mask) { out[k++] = (uint32_t)(i + (__builtin_ctzll(mask) >> 2)); mask &= mask - 1; }
    }
    for (; i < n; i++) if (is_ctl(p[i])) out[k++] = (uint32_t)i;
    return k;
}
// 64-byte step with an all-clear fast path (long printable runs skip 64 bytes at once)
__attribute__((noinline)) size_t pos_neon_bulk64(const uint8_t *p, size_t n, uint32_t *out) {
    size_t k = 0, i = 0;
    const uint8x16_t c20 = vdupq_n_u8(0x20), c7f = vdupq_n_u8(0x7F);
    for (; i + 64 <= n; i += 64) {
        uint8x16_t m0 = vorrq_u8(vcltq_u8(vld1q_u8(p + i), c20), vceqq_u8(vld1q_u8(p + i), c7f));
        uint8x16_t m1 = vorrq_u8(vcltq_u8(vld1q_u8(p + i + 16), c20), vceqq_u8(vld1q_u8(p + i + 16), c7f));
        uint8x16_t m2 = vorrq_u8(vcltq_u8(vld1q_u8(p + i + 32), c20), vceqq_u8(vld1q_u8(p + i + 32), c7f));
        uint8x16_t m3 = vorrq_u8(vcltq_u8(vld1q_u8(p + i + 48), c20), vceqq_u8(vld1q_u8(p + i + 48), c7f));
        uint8x16_t any = vorrq_u8(vorrq_u8(m0, m1), vorrq_u8(m2, m3));
        if (vmaxvq_u8(any) == 0) continue;
        uint8x16_t ms[4] = {m0, m1, m2, m3};
        for (int q = 0; q < 4; q++) {
            uint64_t mask = vget_lane_u64(vreinterpret_u64_u8(vshrn_n_u16(vreinterpretq_u16_u8(ms[q]), 4)), 0) & 0x8888888888888888ULL;
            while (mask) { out[k++] = (uint32_t)(i + q * 16 + (__builtin_ctzll(mask) >> 2)); mask &= mask - 1; }
        }
    }
    for (; i < n; i++) if (is_ctl(p[i])) out[k++] = (uint32_t)i;
    return k;
}

typedef size_t (*fn_t)(const uint8_t *, size_t, uint32_t *);

// synthetic streams
static size_t gen(uint8_t *b, size_t cap, int kind, unsigned seed) {
    size_t n = 0; srand(seed);
    while (n + 64 < cap) {
        switch (kind) {
        case 0: { int run = 80; for (int i = 0; i < run; i++) b[n++] = 'a' + rand() % 26; b[n++] = '\n'; break; }        // plain text, 80-col lines
        case 1: { n += sprintf((char *)b + n, "\x1b[38;2;%d;%d;%dm", rand() % 256, rand() % 256, rand() % 256); int run = 3 + rand() % 8; for (int i = 0; i < run; i++) b[n++] = 'a' + rand() % 26; break; } // SGR-dense truecolor
        case 2: { n += sprintf((char *)b + n, "\x1b[%d;%dH", 1 + rand() % 50, 1 + rand() % 200); int run = 1 + rand() % 12; for (int i = 0; i < run; i++) b[n++] = 'a' + rand() % 26; break; } // TUI redraw: cursor moves + short text
        case 3: { n += sprintf((char *)b + n, "\x1b[1;32m"); int run = 8 + rand() % 24; for (int i = 0; i < run; i++) b[n++] = 'a' + rand() % 26; n += sprintf((char *)b + n, "\x1b[0m  "); break; } // ls --color-like
        case 4: { // UTF-8 heavy text: 2/3-byte scalars, newline every ~60 chars
            for (int i = 0; i < 60; i++) { int r = rand() % 3; if (r == 0) b[n++] = 'a' + rand() % 26; else if (r == 1) { b[n++] = 0xC3; b[n++] = 0x80 + rand() % 64; } else { b[n++] = 0xE4; b[n++] = 0xB8 + rand() % 8; b[n++] = 0x80 + rand() % 64; } } b[n++] = '\n'; break; }
        }
    }
    return n;
}

static double bench(fn_t f, const uint8_t *buf, size_t n, uint32_t *out, size_t *kk) {
    double best = 1e18;
    for (int rep = 0; rep < 31; rep++) {
        uint64_t t0 = now_ns(); size_t k = 0; int iters = 0;
        while (now_ns() - t0 < 2000000) { k = f(buf, n, out); iters++; __asm__ volatile("" :: "r"(k) : "memory"); }
        double per = (double)(now_ns() - t0) / iters; if (per < best) best = per; *kk = k;
    }
    return best;
}

int main(void) {
    size_t cap = 1u << 20; uint8_t *buf = aligned_alloc(64, cap + 64); uint32_t *out = malloc((cap + 64) * 4), *ref = malloc((cap + 64) * 4);
    const char *names[] = {"plain 80-col text", "SGR truecolor dense", "TUI cursor moves", "ls --color", "UTF-8 heavy"};
    printf("backend=%s\n", adf_kernels_backend());
    // correctness: every variant equals scalar on all kinds + short random inputs at all lengths/alignments
    for (int kind = 0; kind < 5; kind++) {
        size_t n = gen(buf, cap, kind, 7 + kind); size_t kr = pos_scalar(buf, n, ref);
        fn_t fs[] = {pos_aemi_repeat, pos_neon_bulk, pos_neon_bulk64};
        for (int f = 0; f < 3; f++) { size_t k = fs[f](buf, n, out); if (k != kr || memcmp(out, ref, k * 4)) { printf("MISMATCH kind %d fn %d\n", kind, f); return 1; } }
    }
    for (int len = 0; len < 300; len++) for (int off = 0; off < 64; off++) {
        for (int i = 0; i < len + 1; i++) buf[off + i] = (uint8_t)rand();
        size_t kr = pos_scalar(buf + off, len, ref);
        fn_t fs[] = {pos_aemi_repeat, pos_neon_bulk, pos_neon_bulk64};
        for (int f = 0; f < 3; f++) { size_t k = fs[f](buf + off, len, out); if (k != kr || memcmp(out, ref, k * 4)) { printf("MISMATCH len %d off %d fn %d\n", len, off, f); return 1; } }
    }
    printf("correctness: 0 mismatches (5 streams, lengths 0-299 x 64 offsets random bytes)\n\n");
    printf("%-22s %9s | %-10s %-10s %-10s %-10s  (GB/s of input; control density)\n", "stream", "ctl/KiB", "scalar", "aemi-rep", "neon16", "neon64");
    for (int kind = 0; kind < 5; kind++) {
        size_t n = gen(buf, cap, kind, 7 + kind); size_t k;
        double ts = bench(pos_scalar, buf, n, out, &k); double dens = (double)k * 1024 / n;
        double ta = bench(pos_aemi_repeat, buf, n, out, &k), t1 = bench(pos_neon_bulk, buf, n, out, &k), t2 = bench(pos_neon_bulk64, buf, n, out, &k);
        printf("%-22s %9.1f | %-10.2f %-10.2f %-10.2f %-10.2f\n", names[kind], dens, n / ts, n / ta, n / t1, n / t2);
    }
    return 0;
}
