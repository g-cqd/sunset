import Foundation

/// Where the control socket is: in a folder only its user can enter, in the app's support folder.
public enum ControlPath {
    /// `~/Library/Application Support/Sunset/control.sock`.
    public static var standard: String {
        let support =
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appending(path: "Library/Application Support")
        return support.appending(path: "Sunset/control.sock").path(percentEncoded: false)
    }
}
