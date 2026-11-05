// hog: a controlled, repeatable background load for benchmarks ("heavy contention profile", sunset ADR-0017).
// Usage: hog <threads> <seconds> [qos=interactive|initiated|default|utility] [mix=spin|mem|mixed]
// spin  : dependent integer + floating-point chains (occupies a core, no memory traffic)
// mem   : streams copies over a 256 MiB buffer per thread (memory bandwidth and cache eviction)
// mixed : alternates the two per thread (even threads spin, odd threads stream)
// Threads run until the deadline; the process prints the work done per thread so two profiles can be compared.
#include <pthread.h>
#include <pthread/qos.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
static volatile int stop = 0; static qos_class_t qos = QOS_CLASS_USER_INTERACTIVE;
typedef struct { int id; int mode; uint64_t work; } arg_t;
static void *run(void *p) {
    arg_t *a = p; pthread_set_qos_class_self_np(qos, 0);
    uint64_t x = 88172645463325252ULL + (uint64_t)a->id; double f = 1.0000001;
    if (a->mode == 1) {
        size_t n = 256u << 20; uint8_t *s = malloc(n), *d = malloc(n); memset(s, 1, n); memset(d, 2, n);
        while (!stop) { memcpy(d, s, n); a->work += n; uint8_t *t = s; s = d; d = t; }
    } else {
        while (!stop) { for (int i = 0; i < 100000; i++) { x ^= x << 13; x ^= x >> 7; x ^= x << 17; f = f * 1.0000001 + (double)(x & 1) * 1e-9; } a->work += 100000; }
    }
    if (f == 0.5) puts("");
    return NULL;
}
int main(int argc, char **argv) {
    int n = argc > 1 ? atoi(argv[1]) : 8; int secs = argc > 2 ? atoi(argv[2]) : 10;
    if (argc > 3) { if (!strcmp(argv[3], "initiated")) qos = QOS_CLASS_USER_INITIATED; else if (!strcmp(argv[3], "default")) qos = QOS_CLASS_DEFAULT; else if (!strcmp(argv[3], "utility")) qos = QOS_CLASS_UTILITY; }
    const char *mix = argc > 4 ? argv[4] : "mixed";
    pthread_t th[256]; arg_t args[256];
    for (int i = 0; i < n; i++) { args[i] = (arg_t){i, !strcmp(mix, "mem") ? 1 : !strcmp(mix, "spin") ? 0 : (i & 1), 0}; pthread_create(&th[i], NULL, run, &args[i]); }
    struct timespec ts = {secs, 0}; nanosleep(&ts, NULL); stop = 1;
    for (int i = 0; i < n; i++) pthread_join(th[i], NULL);
    double tot = 0; for (int i = 0; i < n; i++) tot += (double)args[i].work; printf("hog: %d threads, %d s, mix=%s, total work units %.3g\n", n, secs, mix, tot);
    return 0;
}
