public import Foundation

/// The windows the app had open: written when it quits, read at launch. Reading never fails the launch: a file that cannot be understood is no session,
/// and a damaged window is left out.
public struct SavedSession: Sendable, Equatable {
    public static let version = 1
    public private(set) var windows: [SavedWindow]

    /// Windows with no tab are left out.
    public init(windows: [SavedWindow]) { self.windows = windows.filter { !$0.workspace.isEmpty } }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return try encoder.encode(File(version: Self.version, windows: windows.map(Lossy.init)))
    }

    public init?(data: Data) {
        guard let file = try? JSONDecoder().decode(File.self, from: data), file.version == Self.version else {
            return nil
        }
        self.init(windows: file.windows.compactMap(\.value))
    }

    private struct File: Codable {
        let version: Int
        let windows: [Lossy]
    }

    /// A window that fails to read is nil instead of failing the whole file.
    private struct Lossy: Codable {
        let value: SavedWindow?
        init(_ value: SavedWindow) { self.value = value }
        init(from decoder: any Decoder) throws { value = try? SavedWindow(from: decoder) }
        func encode(to encoder: any Encoder) throws { try value?.encode(to: encoder) }
    }
}
