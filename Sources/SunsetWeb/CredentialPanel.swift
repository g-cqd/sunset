import SunsetShell
import SwiftUI

/// The panel of a server that asks for a name and a password (roadmap 0029 step 8), in the middle of its page's pane.
struct CredentialPanel: View {
    let request: CredentialRequest
    @State private var user = ""
    @State private var password = ""
    @FocusState private var typing: Bool
    @Environment(\.surfaceStyle) private var surface

    var body: some View {
        ZStack {
            Color.black.opacity(Design.Fill.veil).contentShape(.rect).onTapGesture {}
            VStack(alignment: .leading, spacing: Design.Space.l) {
                Text(request.title).font(Design.Text.body.weight(.semibold))
                if !request.realm.isEmpty { Text(verbatim: request.realm).foregroundStyle(.secondary) }
                if let warning = request.warning {
                    Label(warning, systemImage: "exclamationmark.triangle").font(Design.Text.detail)
                }
                TextField("Name", text: $user).textFieldStyle(.roundedBorder).focused($typing)
                SecureField("Password", text: $password).textFieldStyle(.roundedBorder)
                HStack {
                    Spacer()
                    Button("Cancel") { request.answer(nil) }.keyboardShortcut(.cancelAction)
                    Button("Sign In") { request.answer(.init(user: user, password: password)) }
                        .keyboardShortcut(.defaultAction)
                        .disabled(user.isEmpty)
                }
            }
            .padding(Design.Space.xl)
            .frame(width: Design.Width.panel, alignment: .leading)
            .surface(surface.panelShape, shadow: .popover)
            .padding(Design.Space.l)
        }
        .onAppear { typing = true }
    }
}
