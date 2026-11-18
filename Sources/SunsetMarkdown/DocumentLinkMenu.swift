package import AppKit
package import SunsetShell
package import SwiftUI

/// The menu of a link of a rendered document (roadmap 0042 C), as a page's link has one: where it opens, and Copy Link.
package enum DocumentLinkMenu {
    /// One place to open the link in.
    package struct Item: Equatable, Sendable {
        package let title: String
        package let place: LinkPlace
    }

    /// The places, in the menu's order; the same for a web address and a file.
    /// - Parameter url: where the link leads.
    /// - Returns: the items.
    package static func items(for url: URL) -> [Item] {
        [
            Item(title: "Open in New Tab", place: .tab),
            Item(title: "Open in Background Tab", place: .backgroundTab),
            Item(title: "Open Beside", place: .beside),
            Item(title: "Open in New Window", place: .window)
        ]
    }

    /// Copies the link: a web address as written, a file as its path.
    /// - Parameters:
    ///   - url: where the link leads.
    ///   - board: the pasteboard; the general one by default.
    /// - Returns: What it did, for the person to be told.
    @discardableResult
    package static func copy(_ url: URL, to board: NSPasteboard = .general) -> ActionFeedback {
        Clipboard.copy(
            url.isFileURL ? url.path : url.absoluteString,
            isLink: !url.isFileURL,
            what: url.isFileURL ? "Copied the path" : "Copied the link",
            to: board
        )
    }

    /// The menu's items, for a link of `content`'s page.
    struct Buttons: View {
        let url: URL
        let content: DocumentContent

        var body: some View {
            ForEach(DocumentLinkMenu.items(for: url), id: \.title) { item in
                Button(item.title) { content.open(link: url, in: item.place) }
            }
            Divider()
            Button("Copy Link") { Feedback.give(DocumentLinkMenu.copy(url)) }
        }
    }
}
