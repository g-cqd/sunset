/// Something on screen the easter egg clears and puts back: a window of Sunset's (minimized), another app (hidden).
package protocol ClearableOnScreen: AnyObject {
    /// On screen now: not minimized, not hidden.
    var isShown: Bool { get }
    func clear()
    func bringBack()
}
