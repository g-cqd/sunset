import SwiftUI

extension SpaceSlide {
    /// Eased in and out over the time given, as the sidebar's rows move.
    @MainActor package static let animated: Runner = { duration, change, completion in
        withAnimation(.easeInOut(duration: duration), change, completion: completion)
    }

    /// A change in one step, no animation.
    @MainActor package static let plain: @MainActor (() -> Void) -> Void = { change in
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, change)
    }
}
