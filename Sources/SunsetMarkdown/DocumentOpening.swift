package import Foundation

/// What a document pane asks to have opened beside it (R6: "everything in a new split").
package enum DocumentOpening {
    /// Another pane on a document: the other view of the same one (Show Beside), or the file a link names.
    case document(DocumentContent)
    /// A web address, as a page.
    case web(URL)
    /// What is not Sunset's to show: mail, a folder.
    case system(URL)
}
