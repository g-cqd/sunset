package import Foundation
package import SunsetConfig

/// What opens when Sunset, or a window on an empty Space, starts with no tab (the owner's note n74), from `tabs.start`.
package enum StartTab: Equatable, Sendable {
    case nothing
    case terminal
    /// A page at the address, or a new one asking for it (nil).
    case page(URL?)
    case newDocument
    /// The document file at the path.
    case file(String)

    /// From the setting: an address as the address field reads one (https:// when it has no scheme), a file's path with
    /// ~ expanded; nothing when the one asked for is empty.
    package static func resolve(_ tabs: Configuration.Tabs) -> Self {
        switch tabs.start {
            case .nothing:
                return .nothing
            case .terminal:
                return .terminal
            case .web:
                return .page(nil)
            case .newDocument:
                return .newDocument
            case .address:
                let typed = tabs.startAddress.trimmingCharacters(in: .whitespaces)
                guard !typed.isEmpty else { return .nothing }
                let text = typed.contains("://") ? typed : "https://" + typed
                return URL(string: text).map { .page($0) } ?? .nothing
            case .file:
                let typed = tabs.startFile.trimmingCharacters(in: .whitespaces)
                guard !typed.isEmpty else { return .nothing }
                return .file((typed as NSString).expandingTildeInPath)
        }
    }
}
