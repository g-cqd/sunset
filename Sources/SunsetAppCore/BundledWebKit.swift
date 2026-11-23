/// Sunset WebKit: the build that bundles our WebKit in its Frameworks. Sunset's executable sets the loader's framework
/// path to that folder itself (LC_DYLD_ENVIRONMENT, project.yml; diary 2026-11-23-05), as do WebKit's processes'
/// executables (Engine/WebKit/service-main.c): no exception for the environment's loader variables, no running again
/// (CRIT-02; until 2026-11-23 it ran itself again with `DYLD_FRAMEWORK_PATH` set).
package enum BundledWebKit {
    /// The Info.plist key `Scripts/make-webkit-app.sh` writes: the WebKit base the build bundles. The native build has none.
    package static let marker = "SunsetWebKitBase"
}
