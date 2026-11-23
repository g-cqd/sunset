// Roadmap 0113 step A: a WebKit process (XPC service) that does not link WebKit. It loads WebKit's frameworks from a
// folder fixed when it is built, then hands over to WebKit's own service entry point, as WebKit's services do.
//
//   clang -O2 -DENGINE='"/path/to/Frameworks"' Scripts/probes/webkit-service-shim.c -o SHIM
//
// The service bundle is WebKit's own (its Info.plist, its entitlements); only its executable is this.
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef ENGINE
#error "ENGINE: the folder of WebKit's frameworks"
#endif

static const char *order[] = {
    "libwebrtc.dylib", "libANGLE-shared.dylib", "JavaScriptCore.framework/JavaScriptCore", "WebGPU.framework/WebGPU",
    "WebCore.framework/WebCore", "WebKitLegacy.framework/WebKitLegacy", "WebKit.framework/WebKit",
};

int main(int argc, const char **argv) {
    void *webKit = NULL;
    for (unsigned i = 0; i < sizeof order / sizeof *order; i++) {
        char path[4096];
        snprintf(path, sizeof path, "%s/%s", ENGINE, order[i]);
        void *handle = dlopen(path, RTLD_NOW | RTLD_GLOBAL);
        if (!handle) {
            fprintf(stderr, "shim: %s\n", dlerror());
            return 70;
        }
        webKit = handle;
    }
    int (*serviceMain)(int, const char **) = (int (*)(int, const char **))dlsym(webKit, "WKXPCServiceMain");
    if (!serviceMain) {
        fprintf(stderr, "shim: no WKXPCServiceMain\n");
        return 70;
    }
    return serviceMain(argc, argv);
}
