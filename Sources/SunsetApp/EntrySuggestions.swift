import SunsetCredentials
import SwiftUI

/// The entries a card's or a contact field is offered, as a menu's items (`FillMenuRow`): each by its title and what
/// tells it apart (a card's last four digits, an identity's email); nothing is filled until one is clicked.
struct EntrySuggestions: View {
    struct Offer {
        let entry: VaultEntry
        let detail: String
    }

    let offers: [Offer]
    /// A card for cards, a person for identities.
    let symbol: String
    let choose: (VaultEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(offers.prefix(Self.most), id: \.entry.id) { offer in
                FillMenuRow(title: PasswordLook.title(offer.entry), detail: offer.detail, symbol: symbol) {
                    choose(offer.entry)
                }
            }
        }
        .padding(Self.inset)
        .frame(width: Self.width)
    }

    private static let most = 5
    private static let inset = 5.0
    private static let width = 260.0
}
