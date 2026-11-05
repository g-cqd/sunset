// rusage_sample <pid> <seconds>: physical footprint and, over the interval, wakeups, instructions and cycles of one process (proc_pid_rusage, RUSAGE_INFO_V4).
// Deterministic-ish counters (not wall time): used for idle and footprint comparisons between terminals (sunset roadmap 0014).
#include <libproc.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/resource.h>
#include <unistd.h>
static int get(pid_t p, struct rusage_info_v4 *r) { return proc_pid_rusage(p, RUSAGE_INFO_V4, (rusage_info_t *)r); }
int main(int argc, char **argv) {
    pid_t pid = (pid_t)atoi(argv[1]); int secs = atoi(argv[2]); struct rusage_info_v4 a, b;
    if (get(pid, &a)) { fprintf(stderr, "proc_pid_rusage failed for %d\n", pid); return 1; }
    sleep((unsigned)secs);
    if (get(pid, &b)) { fprintf(stderr, "process gone\n"); return 1; }
    printf("footprint_MB=%.1f peak_footprint_MB=%.1f intr_wakeups_per_s=%.1f idle_wakeups_per_s=%.1f Minstr_per_s=%.3f Mcyc_per_s=%.3f cpu_ms_per_s=%.2f\n",
           b.ri_phys_footprint / 1048576.0, b.ri_lifetime_max_phys_footprint / 1048576.0,
           (double)(b.ri_interrupt_wkups - a.ri_interrupt_wkups) / secs, (double)(b.ri_pkg_idle_wkups - a.ri_pkg_idle_wkups) / secs,
           (double)(b.ri_instructions - a.ri_instructions) / secs / 1e6, (double)(b.ri_cycles - a.ri_cycles) / secs / 1e6,
           (double)((b.ri_user_time + b.ri_system_time) - (a.ri_user_time + a.ri_system_time)) / 1e6 / secs);
    return 0;
}
