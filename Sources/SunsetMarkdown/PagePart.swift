internal import SunsetDocuments

/// A part of a document's text as the page shows it while conflicts wait (roadmap 0023 step M-e): the text between two
/// conflicts, or the blocks of a conflict as they are here (with the conflict, which holds what the disk says).
struct PagePart: Identifiable, Equatable {
    /// A conflict's is its own, so that the page can be scrolled to it; a text's is below zero, by its place.
    let id: Int
    let text: String
    let conflict: DocumentConflict?
}
