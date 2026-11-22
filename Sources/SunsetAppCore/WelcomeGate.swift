/// Whether the welcome opens by itself: on the first launch only, never over what someone already set up.
public enum WelcomeGate {
    /// - Parameters:
    ///   - configurationExisted: a configuration file was there when Sunset started (someone, or a test, set it up).
    ///   - seen: the welcome was shown before (its marker beside the configuration).
    ///   - background: started behind what the person is doing (`SUNSET_BACKGROUND`).
    ///   - asked: started to show it (`SUNSET_WELCOME=1`: a test copy, which has a configuration and runs in the background).
    /// - Returns: whether it opens, and the main window waits for it to close.
    public static func opensByItself(configurationExisted: Bool, seen: Bool, background: Bool, asked: Bool = false)
        -> Bool
    {
        asked || (!configurationExisted && !seen && !background)
    }
}
