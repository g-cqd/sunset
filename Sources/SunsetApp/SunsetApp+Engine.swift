import SunsetAppCore

extension SunsetApp {
    /// Sunset WebKit refuses to run on a WebKit other than its own; the native build does nothing here. Called before
    /// `main()`.
    public static func pointAtBundledWebKit() {
        BundledWebKit.refuseOtherWebKit()
    }
}
