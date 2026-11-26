/// What the app does with the sign-in fields of pages: suggest, and offer to save (the vault is the app's).
@MainActor
package protocol PasswordFillHost: AnyObject {
    func loginField(focused field: LoginField, in page: WebContent)
    func loginFieldBlurred(in page: WebContent)
    func loginSent(_ login: SentLogin, in page: WebContent)
    /// A sign-in form is shown in a page that is not private, at load or soon after (`field` its password).
    func loginFormShown(_ field: LoginField, in page: WebContent)
}
