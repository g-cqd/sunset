public import Foundation

/// The staged bundle put in the running one's place in one step (ADR-0122): `renamex_np` with `RENAME_SWAP` exchanges the
/// two folders atomically on one volume; the former app is then at the staging path, for the caller to move to the Trash.
/// A running app keeps running from the files it has open.
public enum BundleSwap {
    public enum Failure: Error, Equatable {
        /// The swap was refused (another volume, no right to write the app's folder): `errno`.
        case refused(Int32)
    }

    /// Swaps `staging` into `running`'s place.
    public static func swap(running: URL, staging: URL) throws(Failure) {
        let swapped = running.withUnsafeFileSystemRepresentation { from in
            staging.withUnsafeFileSystemRepresentation { to in
                guard let from = unsafe from, let to = unsafe to else { return Int32(-1) }
                return unsafe renamex_np(from, to, UInt32(RENAME_SWAP))
            }
        }
        guard swapped == 0 else { throw .refused(errno) }
    }
}
