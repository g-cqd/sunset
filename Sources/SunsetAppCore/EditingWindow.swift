/// The window whose pane the editing menus act on (Format: ⌘B, ⌘I, ⌘K, ⇧⌘K, ⇧⌘X): the key window when it is a tab window,
/// and none otherwise. A key typed in a web pop-up, a sheet or the Passwords setup belongs to that window; falling back to
/// the main window would edit a document behind it.
public enum EditingWindow {
    public static func target<Window: AnyObject>(key: Window?, isTabWindow: (Window) -> Bool) -> Window? {
        guard let key, isTabWindow(key) else { return nil }
        return key
    }
}
