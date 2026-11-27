import SunsetCredentials
import SunsetRuntime
import SunsetShell
import SwiftUI

/// The codes a one-time code's field is offered: each entry's code now, as a menu item (`FillMenuRow`), redrawn as it
/// changes; nothing is filled until one is clicked.
struct CodeSuggestions: View {
    let offers: [CodeOffer]
    let choose: (CodeOffer) -> Void

    var body: some View {
        TimelineView(.periodic(from: Runtime.live.now(), by: 1)) { context in
            VStack(alignment: .leading, spacing: Design.Space.hair) {
                ForEach(offers.prefix(Self.most), id: \.entry.id) { offer in
                    FillMenuRow(
                        title: OneTimeCodeField.spaced(offer.field.code(at: context.date)),
                        detail: PasswordLook.title(offer.entry),
                        monospaced: false
                    ) { choose(offer) }
                }
            }
        }
        .padding(FillMenuRow.inset)
        .frame(width: Self.width)
    }

    private static let most = 5
    private static let width = 264.0
}
