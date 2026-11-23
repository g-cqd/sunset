// The executable of each of WebKit's processes in Sunset WebKit (roadmap 0113, diary 2026-11-23-05, CRIT-02): WebKit's
// own service entry point, linked with the loader's framework path set in the executable (LC_DYLD_ENVIRONMENT, toward
// the app's Frameworks), so that the service runs on the app's WebKit with no exception for the environment's loader
// variables. Scripts/make-webkit-app.sh builds it for each service.
extern int WKXPCServiceMain(int argc, const char **argv);

int main(int argc, const char **argv) {
    return WKXPCServiceMain(argc, argv);
}
