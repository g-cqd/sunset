import SunsetAppCore

extension SunsetApp {
    /// Sunset WebKit refuses to run on a WebKit other than its own; the native build sets an incomplete engine beside it
    /// aside and runs again. Called before `main()`.
    public static func pointAtBundledWebKit() {
        BundledWebKit.refuseOtherWebKit()
        EngineFolder.setAsideIfMixed()
    }
}
