public enum MouseTracking: UInt8, Sendable {
    case none
    /// Press only (mode 9).
    case x10
    /// Press and release (1000).
    case normal
    /// Plus motion while a button is held (1002).
    case button
    /// Plus all motion (1003).
    case any
}
