public import Foundation

/// Where a document is: a file of the person's, or a document that lives in Sunset's store.
public enum DocumentPlace: Hashable, Sendable {
    case file(String)
    case stored(UUID)

    /// What a pane's saved state holds of it.
    public var state: [String: String] {
        switch self {
            case .file(let path): ["file": path]
            case .stored(let id): ["document": id.uuidString]
        }
    }

    public init?(state: [String: String]) {
        if let path = state["file"], !path.isEmpty {
            self = .file(path)
        } else if let id = state["document"].flatMap(UUID.init(uuidString:)) {
            self = .stored(id)
        } else {
            return nil
        }
    }

    /// The one name of this place, so that a file reached by a link, or by a path with `.` and `..` in it, is the same
    /// document: the real path of the file, or of its folder when the file is not there yet.
    public var canonical: DocumentPlace {
        guard case .file(let path) = self else { return self }
        let url = URL(fileURLWithPath: path).standardizedFileURL
        if let real = Self.real(url.path) { return .file(real) }
        if let folder = Self.real(url.deletingLastPathComponent().path) {
            return .file(folder + "/" + url.lastPathComponent)
        }
        return .file(url.path)
    }

    private static func real(_ path: String) -> String? {
        guard let resolved = unsafe realpath(path, nil) else { return nil }
        defer { unsafe free(resolved) }
        return unsafe String(cString: resolved)
    }
}
