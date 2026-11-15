import Foundation
import SunsetDocuments
import SunsetPane
import SunsetShell
import Testing

@testable import SunsetMarkdown

/// What quitting would lose of the documents. Closing a pane loses nothing while another shows the document; quitting closes them all.
extension DocumentContentTests {
    @Test func `quitting names each edited document once, however many panes show it`() throws {
        let shared = try file("shared.md", "one\n")
        let first = try content(shared)
        let second = try content(shared, mode: "source")
        let other = try content(try file("other.md", "kept\n"))
        let ids = [PaneID(), PaneID(), PaneID()]
        let panes: [(PaneID?, any PaneContent)] = [(ids[0], first), (ids[1], second), (ids[2], other)]
        #expect(DocumentContent.quitLosses(in: panes).isEmpty, "nothing is edited")

        type("two\n", into: second)
        #expect(first.closeWarning == nil && second.closeWarning == nil, "closing one of the two loses nothing")
        let losses = DocumentContent.quitLosses(in: panes)
        #expect(losses.map(\.text) == ["shared.md has edits that are not saved."])
        #expect(losses.first?.kind == .document && losses.first?.pane == ids[0], "a click on it shows a pane of it")
    }
}
