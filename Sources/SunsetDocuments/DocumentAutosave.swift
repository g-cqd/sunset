/// When a document saves itself (R6, roadmap 0023 step M-d). A file does only when a setting says so, and both settings are
/// off by default; a document of Sunset's own store always does, a moment after an edit ("kept by Sunset until saved").
public struct DocumentAutosave: Sendable, Equatable {
    /// A file is written this long after its first unsaved edit, so no more than that much typing is ever unsaved; nil is
    /// never (`documents.saveAfter`, 0).
    public var fileDelay: Duration?
    /// A file is written when its pane, or the app, stops being the one typed in (`documents.saveOnFocusLoss`).
    public var onFocusLoss = false
    /// The moment after which a document of the store is kept.
    public var storedDelay = Duration.seconds(2)

    public init(fileDelay: Duration? = nil, onFocusLoss: Bool = false, storedDelay: Duration = .seconds(2)) {
        self.fileDelay = fileDelay
        self.onFocusLoss = onFocusLoss
        self.storedDelay = storedDelay
    }

    /// From the settings: `seconds` of 0 or less is never.
    public init(seconds: Double, onFocusLoss: Bool) {
        self.init(fileDelay: seconds > 0 ? .milliseconds(Int64(seconds * 1000)) : nil, onFocusLoss: onFocusLoss)
    }
}
