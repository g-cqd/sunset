public import Foundation

/// Where the engine is beside the app (ADR-0124): `SunsetEngine` (in use), `SunsetEngine (off)` (kept, not used), and
/// `.SunsetEngine-update` (staged, checked). Each change is made as Sunset quits, by renames on one volume, and takes effect
/// when it opens again.
public struct EnginePlace: Sendable {
    public enum State: Equatable, Sendable {
        case none
        case on
        case off
    }

    public enum Change: Equatable, Sendable {
        /// The staged engine in place of the one before (on or off, as it was; on when there was none).
        case install
        case on
        case off
        /// Out of its place, to the Trash.
        case remove
    }

    public let engine: URL
    public let offFolder: URL
    public let staging: URL

    /// The places beside the app at `app`.
    public init(beside app: URL) {
        let folder = app.deletingLastPathComponent()
        engine = folder.appending(path: "SunsetEngine")
        offFolder = folder.appending(path: "SunsetEngine (off)")
        staging = folder.appending(path: ".SunsetEngine-update")
    }

    public var state: State {
        if exists(engine) { return .on }
        return exists(offFolder) ? .off : .none
    }

    /// The installed engine's manifest, on or off.
    public var installed: EngineManifest? {
        EngineManifest.read(from: engine) ?? EngineManifest.read(from: offFolder)
    }

    /// Makes `change`; returns a folder to move to the Trash (an engine replaced or removed), if any.
    public func apply(_ change: Change) throws -> URL? {
        let files = FileManager.default
        switch change {
            case .install:
                let target = state == .off ? offFolder : engine
                guard exists(target) else {
                    try files.moveItem(at: staging, to: target)
                    return nil
                }
                try BundleSwap.swap(running: target, staging: staging)
                return staging
            case .on:
                if state == .off { try files.moveItem(at: offFolder, to: engine) }
                return nil
            case .off:
                if state == .on { try files.moveItem(at: engine, to: offFolder) }
                return nil
            case .remove:
                let current = state == .on ? engine : offFolder
                guard exists(current) else { return nil }
                let away = current.deletingLastPathComponent()
                    .appending(path: ".SunsetEngine-removed-\(UUID().uuidString)")
                try files.moveItem(at: current, to: away)
                return away
        }
    }

    private func exists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}
