/// Where the sign-in fields of pages are told: the app's vault (`PasswordFill`).
@MainActor
package enum PasswordFillHosting {
    package static func set(_ host: any PasswordFillHost) {
        PasswordFill.host = host
    }
}
