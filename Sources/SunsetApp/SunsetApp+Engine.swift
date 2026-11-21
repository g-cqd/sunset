import SunsetAppCore

extension SunsetApp {
    /// Sunset WebKit (ADR-0111) runs itself again first, with the loader pointed at the WebKit inside it; the native build
    /// does nothing here. Called before `main()`.
    public static func pointAtBundledWebKit() {
        BundledWebKit.runAgainIfNeeded()
        BundledWebKit.refuseOtherWebKit()
    }
}
