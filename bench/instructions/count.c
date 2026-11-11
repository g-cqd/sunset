// Runs a command and prints the instructions it retired, in millions (proc_pid_rusage, read until the child is gone).
#include <libproc.h>
#include <stdio.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <unistd.h>

int main(int argc, char **argv) {
    if (argc < 2) return 2;
    pid_t child = fork();
    if (child == 0) {
        int null = fileno(fopen("/dev/null", "w"));
        dup2(null, 1);
        execvp(argv[1], argv + 1);
        _exit(127);
    }
    struct rusage_info_v4 info;
    unsigned long long instructions = 0;
    int status = 0;
    for (;;) {
        if (proc_pid_rusage(child, RUSAGE_INFO_V4, (rusage_info_t *)&info) == 0) instructions = info.ri_instructions;
        if (waitpid(child, &status, WNOHANG) == child) break;
        usleep(1000);
    }
    printf("%.1f\n", instructions / 1e6);
    return 0;
}
