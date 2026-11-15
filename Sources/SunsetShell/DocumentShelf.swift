package import Foundation

/// The documents of the store as the shell reaches them (roadmap 0030 step ST-5): the app says how they are listed, made and
/// deleted; the shell does not know the store. With nothing said there are none.
@MainActor
package final class DocumentShelf {
    /// The documents, in any order. Read while a view is drawn, so what it reads is followed.
    package var list: () -> [ShelfDocument] = { [] }
    /// Makes a new empty document; nil when none can be kept in this run.
    package var create: () -> UUID? = { nil }
    /// Puts the document away for good (its plain text in the Mac's Trash), in every window.
    package var delete: (UUID) -> Void = { _ in }

    package init() {}
}
