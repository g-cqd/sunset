extension ShellSettings {
    /// The edge of the window something is on.
    package enum Side: String, Sendable, Equatable, CaseIterable {
        case left, right
    }

    /// `sidebar.*`.
    package struct Sidebar: Sendable, Equatable {
        package var enabled = true
        /// Width in points.
        package var width = 229.0
        /// Space of the window's colour between the content and the window's edge and the sidebar while the sidebar is shown, in points.
        package var padding = 4.0
        /// The sidebar is hidden and floats over the content while the pointer is at its edge; false: it stays beside the content.
        package var autoHide = false
        package var side = Side.right
        /// The Library's glyph is at the sidebar's foot.
        package var library = true
        /// The order of the documents in the sidebars' lists.
        package var documentSort = DocumentSort.changed
        /// The lines between the Pinned grid, the Favorites and the tabs (`sidebar.separators`).
        package var separators = true
        /// A card when a row is pointed at, and of which kinds (`sidebar.previews`, `sidebar.preview*`).
        package var previews = true
        package var previewPages = true
        package var previewTerminals = true
        package var previewDocuments = true
        package var previewFolders = true

        package init() {}

        /// Which rows show a preview card.
        package var previewKinds: PreviewKinds {
            var kinds = PreviewKinds()
            kinds.enabled = previews
            kinds.pages = previewPages
            kinds.terminals = previewTerminals
            kinds.documents = previewDocuments
            kinds.folders = previewFolders
            return kinds
        }
    }

    /// `tabs.*`, as far as the shell's views read it.
    package struct Tabs: Sendable, Equatable {
        package var bar = Bar()

        package init() {}
    }

    /// `tabs.bar.*`: what a tab's row shows.
    package struct Bar: Sendable, Equatable {
        package enum Position: String, Sendable, Equatable, CaseIterable {
            case top, bottom
        }

        package var position = Position.bottom
        package var showTitle = true
        /// A small picture before the title.
        package var showIcon = true
        package var showDirectory = true
        /// The second line in the monospaced face.
        package var monospacedDirectory = true
        package var showProgress = true
        /// Hidden over the page until the pointer reaches its edge.
        package var autoHide = true
        /// Under it while shown always: the page fading, or a toolbar.
        package var backing = Backing.fade

        /// What is under the bar while it is shown always.
        package enum Backing: Equatable, Sendable {
            case fade, toolbar
        }

        package init() {}
    }
}
