// Roadmap 0113, diary 2026-11-23-05: does a hardened executable with LC_DYLD_ENVIRONMENT (DYLD_FRAMEWORK_PATH set at
// link time) run on the WebKit of that folder, system frameworks that link WebKit included, with no loader exception?
//   clang -fobjc-arc -framework Foundation -framework WebKit Scripts/probes/webkit-dyld-env.m -o P \
//       -Wl,-dyld_env,DYLD_FRAMEWORK_PATH=FOLDER     (then sign it hardened; an argument lists the images)

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
int main(int argc, const char **argv) {
    @autoreleasepool {
        (void)[WKWebView class];
        dlopen("/System/Library/Frameworks/LinkPresentation.framework/LinkPresentation", RTLD_NOW);
        dlopen("/System/Library/Frameworks/AVKit.framework/AVKit", RTLD_NOW);
        int sys = 0, ours = 0;
        for (uint32_t i = 0; i < _dyld_image_count(); i++) {
            const char *n = _dyld_get_image_name(i);
            if (strstr(n, "/WebKit.framework/") || strstr(n, "/WebCore.framework/") || strstr(n, "/JavaScriptCore.framework/")) {
                if (strncmp(n, "/System/", 8) == 0) sys++; else ours++;
                if (argc > 1) printf("%s\n", n);
            }
        }
        printf("ours %d, system's %d; WKWebView from %s\n", ours, sys, [[NSBundle bundleForClass:[WKWebView class]].bundlePath UTF8String]);
    }
    return 0;
}
