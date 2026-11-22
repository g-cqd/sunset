import Foundation

/// Sunset WebKit: the build that bundles our WebKit runs Sunset on it by pointing the dynamic loader at the app's
/// frameworks, for Sunset and for WebKit's processes (the `__XPC_` variables are handed to the XPC services WebKit
/// starts). Sunset is the app's main executable (macOS honours the team's entitlements only there: a launcher running it
/// as a second executable was killed, 2026-11-20), so it runs itself again, once, with the loader's variables set.
package enum BundledWebKit {
    /// The Info.plist key `Scripts/make-webkit-app.sh` writes: the WebKit base the build bundles. The native build has none.
    package static let marker = "SunsetWebKitBase"

    /// The environment to run again with, or nil when there is nothing to do: the native build, or already pointed at
    /// the app's frameworks. Only the app's frameworks: what the environment held for the loader is replaced, and no
    /// library is inserted.
    package static func environment(info: [String: Any], environment: [String: String], bundle: String) -> [String:
        String]?
    {
        guard info[marker] != nil else { return nil }
        let frameworks = bundle + "/Contents/Frameworks"
        var wanted = environment
        for name in ["DYLD_FRAMEWORK_PATH", "DYLD_LIBRARY_PATH", "__XPC_DYLD_FRAMEWORK_PATH", "__XPC_DYLD_LIBRARY_PATH"]
        {
            wanted[name] = frameworks
        }
        wanted["DYLD_INSERT_LIBRARIES"] = nil
        wanted["__XPC_DYLD_INSERT_LIBRARIES"] = nil
        return wanted == environment ? nil : wanted
    }

    /// Runs this executable again with `environment(…)`'s variables, when there are any; returns when there is nothing to
    /// do or it could not (then Sunset runs on the system's WebKit, and says so on the standard error).
    package static func runAgainIfNeeded() {
        let main = Bundle.main
        guard
            let info = main.infoDictionary,
            let wanted = environment(
                info: info,
                environment: ProcessInfo.processInfo.environment,
                bundle: main.bundlePath
            ),
            let executable = main.executablePath
        else { return }
        let arguments = [executable] + CommandLine.arguments.dropFirst()
        let argv = arguments.map { strdup($0) } + [nil]
        let envp = wanted.map { strdup("\($0.key)=\($0.value)") } + [nil]
        execve(executable, argv, envp)
        FileHandle.standardError.write(
            Data("Sunset WebKit: could not point the loader at its WebKit (\(errno))\n".utf8)
        )
    }
}
