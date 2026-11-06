// rusage_total <pid>: the process's lifetime counters (proc_pid_rusage): instructions, cycles, CPU time (user + system, in ms), peak footprint (MB), interrupt wakeups.
// Run twice and subtract to get the cost of something that happened in between (sunset roadmap 0014).
#include <libproc.h>
#include <mach/mach_time.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/resource.h>
int main(int argc, char **argv) {
    struct rusage_info_v4 r;
    if (argc < 2 || proc_pid_rusage((pid_t)atoi(argv[1]), RUSAGE_INFO_V4, (rusage_info_t *)&r)) { fprintf(stderr, "failed\n"); return 1; }
    mach_timebase_info_data_t tb; mach_timebase_info(&tb);
    double cpu_ms = (double)(r.ri_user_time + r.ri_system_time) * tb.numer / tb.denom / 1e6;
    printf("%llu %llu %.1f %.1f %llu\n", r.ri_instructions, r.ri_cycles, cpu_ms, r.ri_lifetime_max_phys_footprint / 1048576.0, r.ri_interrupt_wkups);
    return 0;
}
