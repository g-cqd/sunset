// Probe 3: platform libcompression baselines + raw-cell pages vs a structural encoding, on synthetic terminal pages built from real text.
#include <compression.h>
#include <mach/mach_time.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static uint64_t now_ns(void) { static mach_timebase_info_data_t tb; if (!tb.denom) mach_timebase_info(&tb); return mach_absolute_time() * tb.numer / tb.denom; }
#define COLS 120
int main(int argc, char **argv) {
    FILE *f = fopen(argv[1], "rb"); fseek(f, 0, SEEK_END); long sz = ftell(f); fseek(f, 0, SEEK_SET); uint8_t *txt = malloc(sz); fread(txt, 1, sz, f); fclose(f);
    // rows of COLS cells from the text lines (wrapped), style id: 0 default, comment lines 3, string-ish 5, every 7th word-run 2 (synthetic).
    size_t maxrows = 200000, rows = 0; uint64_t *cells = calloc(maxrows * COLS, 8); size_t text_bytes = 0, runs = 0;
    uint8_t *tx = malloc(maxrows * COLS * 4); size_t txn = 0; uint8_t *rn = malloc(maxrows * COLS * 3); size_t rnn = 0; // structural: text + runs
    size_t i = 0;
    while (i < (size_t)sz && rows < maxrows) {
        size_t e = i; while (e < (size_t)sz && txt[e] != '\n' && e - i < COLS) e++;
        uint64_t *row = cells + rows * COLS; int style = 0, prev = -1; size_t runlen = 0;
        for (size_t c = 0; c < COLS; c++) {
            uint8_t b = (i + c < e) ? txt[i + c] : ' ';
            if (b == '/' && i + c + 1 < e && txt[i + c + 1] == '/') style = 3; if (b == '"') style = style == 5 ? 0 : 5; if (b == ' ' && style != 3 && style != 5) style = (c / 9) % 7 == 0 ? 2 : 0;
            row[c] = ((uint64_t)b << 2) | ((uint64_t)style << 24);
            if (style != prev) { if (prev >= 0) { rn[rnn++] = (uint8_t)prev; rn[rnn++] = (uint8_t)runlen; runs++; } prev = style; runlen = 0; } runlen++;
        }
        rn[rnn++] = (uint8_t)prev; rn[rnn++] = (uint8_t)runlen; runs++;
        size_t last = e - i; memcpy(tx + txn, txt + i, last); txn += last; tx[txn++] = '\n'; // trailing blanks trimmed
        rows++; i = e; if (i < (size_t)sz && txt[i] == '\n') i++;
    }
    size_t raw = rows * COLS * 8; printf("rows=%zu cols=%d raw cells=%zu B (8 B/cell); structural: text %zu B + runs %zu B (%zu runs) = %zu B\n", rows, COLS, raw, txn, rnn, runs, txn + rnn);
    printf("structural / raw = %.2f%% (%.2f B per cell)\n\n", 100.0 * (txn + rnn) / raw, (double)(txn + rnn) / (rows * COLS));
    struct { const char *n; compression_algorithm a; } algs[] = {{"LZ4_RAW", COMPRESSION_LZ4_RAW}, {"LZFSE", COMPRESSION_LZFSE}, {"ZLIB", COMPRESSION_ZLIB}};
    size_t page = 215 * 215 * 8 / 1; // ghostty std page ~ 370 KB; use 1 MiB chunks
    size_t chunk = 1 << 20; uint8_t *out = malloc(chunk * 2), *back = malloc(chunk);
    for (int k = 0; k < 3; k++) {
        size_t tot_c = 0; double tc = 0, td = 0;
        for (size_t off = 0; off + chunk <= raw; off += chunk) {
            uint64_t t0 = now_ns(); size_t n = compression_encode_buffer(out, chunk * 2, (uint8_t *)cells + off, chunk, NULL, algs[k].a); uint64_t t1 = now_ns();
            size_t m = compression_decode_buffer(back, chunk, out, n, NULL, algs[k].a); uint64_t t2 = now_ns();
            if (m != chunk || memcmp(back, (uint8_t *)cells + off, chunk)) { puts("ROUNDTRIP FAIL"); return 1; }
            tot_c += n; tc += (double)(t1 - t0); td += (double)(t2 - t1);
        }
        size_t nchunks = raw / chunk; double in = (double)nchunks * chunk;
        printf("%-8s ratio %.2f%% of raw (%.2f B/cell)   compress %.2f GB/s   decompress %.2f GB/s\n", algs[k].n, 100.0 * tot_c / in, (double)tot_c / (nchunks * chunk / 8), in / tc, in / td);
    }
    // also: compress the structural form with LZ4_RAW/ZLIB for reference
    uint8_t *sbuf = malloc(txn + rnn); memcpy(sbuf, tx, txn); memcpy(sbuf + txn, rn, rnn); size_t sn = txn + rnn;
    uint8_t *so = malloc(sn * 2); size_t c1 = compression_encode_buffer(so, sn * 2, sbuf, sn, NULL, COMPRESSION_LZ4_RAW), c2 = compression_encode_buffer(so, sn * 2, sbuf, sn, NULL, COMPRESSION_ZLIB);
    printf("\nstructural form further compressed: LZ4_RAW %zu B (%.2f B/cell), ZLIB %zu B (%.2f B/cell)\n", c1, (double)c1 / (rows * COLS), c2, (double)c2 / (rows * COLS));
    (void)page; return 0;
}
