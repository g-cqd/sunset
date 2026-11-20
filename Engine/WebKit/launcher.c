// Sunset on our WebKit (roadmap 0048 C; ADR-0111): the bundled build's executable. It points the dynamic loader at the
// WebKit frameworks inside the app (Contents/Frameworks), for Sunset and for WebKit's processes (the __XPC_ variables are
// handed to the XPC services WebKit starts), then runs Sunset in its place.
//
// The loader's variables, not rewritten links: system frameworks AppKit loads (SafariServices, LinkPresentation,
// DataDetectors…) link the system's WebKit, so with links rewritten both WebKits were in the process (seen 2026-11-20);
// the variables replace the system's for every framework at once, as WebKit's own tools do. Sunset and the services are
// hardened, with the one exception that lets them read these variables (com.apple.security.cs.allow-dyld-environment-
// variables); library validation stays on (the frameworks carry the same team's signature).
#include <libgen.h>
#include <limits.h>
#include <mach-o/dyld.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    (void)argc;
    char executable[PATH_MAX];
    uint32_t size = sizeof(executable);
    if (_NSGetExecutablePath(executable, &size) != 0) {
        fprintf(stderr, "Sunset WebKit: the launcher's path is too long\n");
        return 1;
    }
    char resolved[PATH_MAX];
    if (!realpath(executable, resolved)) {
        perror("Sunset WebKit: realpath");
        return 1;
    }
    char macos[PATH_MAX];
    strlcpy(macos, dirname(resolved), sizeof(macos));
    char contents[PATH_MAX];
    strlcpy(contents, macos, sizeof(contents));
    strlcpy(contents, dirname(contents), sizeof(contents));

    char frameworks[PATH_MAX];
    snprintf(frameworks, sizeof(frameworks), "%s/Frameworks", contents);
    // Only ours: whatever the environment held is replaced, never added to.
    setenv("DYLD_FRAMEWORK_PATH", frameworks, 1);
    setenv("DYLD_LIBRARY_PATH", frameworks, 1);
    setenv("__XPC_DYLD_FRAMEWORK_PATH", frameworks, 1);
    setenv("__XPC_DYLD_LIBRARY_PATH", frameworks, 1);
    unsetenv("DYLD_INSERT_LIBRARIES");
    unsetenv("__XPC_DYLD_INSERT_LIBRARIES");

    char sunset[PATH_MAX];
    snprintf(sunset, sizeof(sunset), "%s/Sunset", macos);
    argv[0] = sunset;
    execv(sunset, argv);
    perror("Sunset WebKit: execv");
    return 1;
}
