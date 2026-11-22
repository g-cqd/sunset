import SunsetCredentials
import SwiftUI

/// The cards a card's field is offered: each by its title and its number's last four digits, as a menu's item
/// (`FillMenuRow`); nothing is filled until one is clicked and the person has said it is them.
struct CardSuggestions: View {
    let offers: [CardOffer]
    let choose: (CardOffer) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(offers.prefix(Self.most), id: \.entry.id) { offer in
                FillMenuRow(
                    title: PasswordLook.title(offer.entry),
                    detail: "\u{2022}\u{2022}\u{2022}\u{2022} \(offer.lastFour)",
                    symbol: "creditcard.fill"
                ) {
                    choose(offer)
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
