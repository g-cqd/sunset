import Foundation

/// The icon a user gives a tab or a folder of the sidebar, over the one its content has (`n40`, `n41`): an SF Symbol by name, or an emoji.
public enum PaneIcon: Sendable, Equatable {
    case symbol(String)
    case emoji(String)
}
