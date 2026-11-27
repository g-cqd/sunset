import SwiftUI

/// What a new password's field is offered (roadmap 0094 E), as macOS offers its own: Use Strong Password, the password
/// made for the page under it, as a menu item (`FillMenuRow`); nothing is filled until it is clicked.
struct StrongPasswordOffer: View {
    let password: String
    let use: () -> Void

    var body: some View {
        FillMenuRow(title: "Use Strong Password", detail: password, monospaced: true, choose: use)
            .padding(FillMenuRow.inset)
            .frame(width: Self.width)
    }

    private static let width = 280.0
}
