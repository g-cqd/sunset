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

        package init() {}
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

        package init() {}
    }
}
