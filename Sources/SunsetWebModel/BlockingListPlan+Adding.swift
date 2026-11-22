import Foundation

/// Lists added and removed in Settings by their address.
extension BlockingListPlan {
    /// The most lists fetched: each is fetched by Sunset itself and compiled, so their number is bounded (white paper §9).
    package static let most = 16

    package enum Adding: Equatable, Sendable {
        /// The lists with the new one last.
        case added([String])
        /// Why it was not added, in a sentence for Settings.
        case refused(String)
    }

    /// `text` added to `lists`: https only, once, at most `most`.
    package static func adding(_ text: String, to lists: [String]) -> Adding {
        let address = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = self.address(address) else {
            return .refused("Only https addresses: a list in the clear could be changed on the way.")
        }
        guard !lists.contains(where: { self.address($0) == url }) else {
            return .refused("That list is already fetched.")
        }
        guard lists.count < most else { return .refused("At most \(most) lists: remove one first.") }
        return .added(lists + [address])
    }

    /// `lists` without `address`.
    package static func removing(_ address: String, from lists: [String]) -> [String] {
        lists.filter { $0 != address }
    }
}
