package import AppKit
package import Foundation
internal import SunsetDocuments
internal import SunsetPane
package import SunsetShell

/// What a document pane does when asked: saving, the other view beside it, a link.
extension DocumentContent {
    /// The folder of the file: what its relative pictures and links are under. A stored document has none.
    package var base: URL? {
        guard case .file(let path) = document.place else { return nil }
        return URL(fileURLWithPath: (path as NSString).deletingLastPathComponent, isDirectory: true)
    }

    /// Writes the document where it lives (Cmd-S). A failure is said in the pane and the edits stay. While a block changed
    /// here and on disk waits for an answer nothing is written: the first of them is shown instead (step M-e).
    package func save() {
        do {
            try document.save()
            failure = nil
        } catch .conflicts {
            failure = nil
            if let first = document.conflicts.first { show(conflict: first.id) }
        } catch {
            failure = error.sentence
        }
    }

    /// The other view of this document in a new pane beside this one (Cmd-Option-E): the same text, so they follow each other.
    package func showBeside() {
        guard canRender else { return }
        onOpen(
            .document(
                DocumentContent(document: documents.open(document.place), mode: mode.other, documents: documents)
            ),
            .beside
        )
    }

    /// A link of the page was followed: where the keys held say, else where `documents.linksOpen` says (the owner,
    /// 2026-11-17); never in this pane.
    package func open(link url: URL, modifiers: NSEvent.ModifierFlags = NSApp?.currentEvent?.modifierFlags ?? []) {
        open(link: url, in: LinkPlace(modifiers: modifiers, besideByDefault: documents.look.linksBeside))
    }

    /// A link of the page opened where its menu said (roadmap 0042 C).
    /// - Parameters:
    ///   - url: where the link leads: a web address, or a file of this Mac.
    ///   - place: where it opens.
    package func open(link url: URL, in place: LinkPlace) {
        guard url.isFileURL else {
            let scheme = url.scheme?.lowercased()
            return onOpen(scheme == "http" || scheme == "https" ? .web(url) : .system(url), place)
        }
        var isFolder: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isFolder), !isFolder.boolValue else {
            // A folder is the Finder's; a file that is not there opens as a document that says so.
            return isFolder.boolValue ? onOpen(.system(url), place) : openDocument(at: url.path, place: place)
        }
        openDocument(at: url.path, place: place)
    }

    private func openDocument(at path: String, place: LinkPlace) {
        onOpen(
            .document(DocumentContent(document: documents.open(.file(path)), mode: nil, documents: documents)),
            place
        )
    }
}

extension DocumentContent {
    /// What a document adds to its tab's menu (the owner's note n8): the other view in place, and beside; nothing for a text
    /// file, which has no page.
    package var menuActions: [PaneMenuAction] {
        guard canRender else { return [] }
        let rendered = mode == .rendered
        return [
            PaneMenuAction(rendered ? "Show Source" : "Show Rendered") { [weak self] in self?.toggleMode() },
            PaneMenuAction(rendered ? "Show Source Beside" : "Show Rendering Beside") { [weak self] in
                self?.showBeside()
            }
        ]
    }
}
