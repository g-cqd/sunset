package import Foundation
import WebKit

/// Filling a page's fields, from Sunset's own world, on the person's act (roadmap 0094, ADR-0094). Each fill is for the
/// origin its suggestion was made for: the script itself checks the page is still there, in the same turn as it fills, so
/// a page that went elsewhere meanwhile (a redirect, a navigation while the suggestion was shown) gets nothing.
extension WebContent {
    /// A username and a password into the sign-in form of the field that has the keyboard (its visible fields only).
    /// Returns whether a password field was filled.
    package func fill(username: String, password: String, for origin: URL) async -> Bool {
        await fill(PasswordFillScript.fill, ["username": username, "secret": password], for: origin)
    }

    /// A new password into the sign-up form of the field that has the keyboard: its password and confirmation fields.
    package func fillNewPassword(_ password: String, for origin: URL) async -> Bool {
        await fill(PasswordFillScript.fillNew, ["secret": password], for: origin)
    }

    /// A one-time code into the code field that has the keyboard, or one character a box into a code split in boxes.
    package func fillCode(_ code: String, for origin: URL) async -> Bool {
        await fill(PasswordFillScript.fillCode, ["code": code], for: origin)
    }

    /// A card into the form of the field that has the keyboard (`number`, `name`, `month`, `year`, `code`).
    package func fillCard(_ card: [String: String], for origin: URL) async -> Bool {
        await fill(PasswordFillScript.fillCard, card, for: origin)
    }

    /// An identity into the form of the contact or address field that has the keyboard, its values by autofill token
    /// (`IdentityOffer`). Returns whether a field was filled.
    package func fillIdentity(_ values: [String: String], for origin: URL) async -> Bool {
        await fill(PasswordFillScript.fillIdentity, ["values": values], for: origin)
    }

    private func fill(_ script: String, _ arguments: [String: Any], for origin: URL) async -> Bool {
        guard let view = webView else { return false }
        var arguments = arguments
        arguments["expected"] = origin.absoluteString.trimmingCharacters(in: ["/"])
        let filled = try? await view.callAsyncJavaScript(
            "if (self.origin !== expected) return false;\n" + script,
            arguments: arguments,
            in: fillFrame,
            contentWorld: .defaultClient
        )
        return filled as? Bool ?? false
    }
}
