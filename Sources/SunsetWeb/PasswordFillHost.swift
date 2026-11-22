/// What the app does with the sign-in fields of pages: suggest, and offer to save (the vault is the app's).
@MainActor
package protocol PasswordFillHost: AnyObject {
    func loginField(focused field: LoginField, in page: WebContent)
    func loginFieldBlurred(in page: WebContent)
    func loginSent(_ login: SentLogin, in page: WebContent)
}
