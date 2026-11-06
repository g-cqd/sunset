#include "csunset_kernels.h"

#if defined(__ARM_NEON)
#include <arm_neon.h>
#endif

size_t sunset_used_length_u64_scalar(const uint64_t *cells, size_t count) {
    while (count > 0 && cells[count - 1] == 0) count--;
    return count;
}

size_t sunset_used_length_u64(const uint64_t *cells, size_t count) {
#if defined(__ARM_NEON)
    // From the end, eight cells (64 bytes) at a time: a block that is all zero is skipped with four loads, an OR and one test; the first block with something
    // in it is finished one element at a time. A row of text is mostly a short line then blanks, so most blocks are the empty ones.
    while (count >= 8) {
        const uint64_t *block = cells + count - 8;
        uint64x2_t merged = vorrq_u64(vorrq_u64(vld1q_u64(block), vld1q_u64(block + 2)),
                                      vorrq_u64(vld1q_u64(block + 4), vld1q_u64(block + 6)));
        if ((vgetq_lane_u64(merged, 0) | vgetq_lane_u64(merged, 1)) != 0) break;
        count -= 8;
    }
#endif
    return sunset_used_length_u64_scalar(cells, count);
}
