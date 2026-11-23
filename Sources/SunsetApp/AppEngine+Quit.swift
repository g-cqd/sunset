import Foundation
import SunsetUpdate

extension AppEngine {
    /// As Sunset ends: the staged engine checked once more and put in place, then on, off or deleted as asked; what is
    /// replaced or deleted to the Trash. Anything wrong leaves the folders as they were.
    func applyAtQuit() {
        guard available, changesAtRestart else { return }
        var trash: [URL] = []
        do {
            if staged != nil {
                try EngineTransfer.check(place.staging, after: installed?.build ?? 0)
                if let former = try place.apply(.install) { trash.append(former) }
            }
            if removing, let removed = try place.apply(.remove) { trash.append(removed) }
            if !removing, let wantsEngine { _ = try place.apply(wantsEngine ? .on : .off) }
        } catch {
            try? FileManager.default.removeItem(at: place.staging)
        }
        for folder in trash { try? FileManager.default.trashItem(at: folder, resultingItemURL: nil) }
    }
}
