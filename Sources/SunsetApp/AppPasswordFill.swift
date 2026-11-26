import AppKit
import LocalAuthentication
import SunsetAppCore
import SunsetConfig
import SunsetCredentials
import SunsetRuntime
import SunsetSiteData
import SunsetWeb
import SwiftUI

/// Filling and saving in pages (roadmap 0094, ADR-0094), as quiet as macOS's own AutoFill: when a sign-in field takes the
/// keyboard and the vault has logins for the page's site, a small popover under the field lists them, and never takes
/// the keyboard; one chosen fills the form. A password sent that the vault does not have is offered to save in a small
/// popover at the page's top. Either goes when clicked away. Nothing while Passwords is off or the vault locked, in a
/// private window, or on a page that is not http or https.
@MainActor
final class AppPasswordFill: PasswordFillHost {
    static let shared = AppPasswordFill()
    private let popover = PasswordFillPopover()

    static func start() {
        PasswordFillHosting.set(shared)
    }

    private var model: PasswordsModel {
        AppPasswords.model
    }

    private var isOn: Bool {
        AppConfiguration.shared.configuration.features.credentials && model.state == .unlocked
    }

    /// A host's site (`LoginSite`), by the Public Suffix List.
    static func site(_ host: String) -> String? {
        LoginSite.of(host) { (try? PublicSuffixList.bundled())?.registrableDomain(of: $0) }
    }

    /// True when `origin` is plain `http://` on a non-loopback host (roadmap 0094 / t103).
    static func isInsecure(_ origin: URL) -> Bool {
        guard origin.scheme?.lowercased() == "http" else { return false }
        let host = (origin.host() ?? "").lowercased()
        return host != "localhost" && host != "127.0.0.1" && host != "::1" && !host.hasSuffix(".localhost")
    }

    func loginField(focused field: LoginField, in page: WebContent) {
        guard isOn, let view = page.webView else { return popover.close() }
        let content: AnyView? =
            switch field.role {
                case .newPassword: newPassword(for: field, in: page)
                case .oneTimeCode: codes(for: field, in: page)
                case .card: cards(for: field, in: page)
                case .identity: identities(for: field, in: page)
                // A sign-in form's field: the site's logins; the one clicked fills the form.
                case .username, .password:
                    shown(LoginMatch.offered(model.entries, for: field.origin, site: Self.site)) { logins in
                        PasswordSuggestions(logins: logins, isInsecureOrigin: Self.isInsecure(field.origin)) {
                            [weak self] entry in
                            self?.fill(entry, in: page, for: field.origin)
                        }
                    }
            }
        guard let content else { return popover.close() }
        popover.show(content, at: field.frame, of: view, edge: .maxY, suggestions: true)
    }

    func loginFieldBlurred(in page: WebContent) {
        popover.closeSuggestions()
    }

    func loginSent(_ login: SentLogin, in page: WebContent) {
        guard isOn, let view = page.webView else { return }
        let sent = SentLoginValues(origin: login.origin, username: login.username, password: login.password)
        guard let offer = LoginSave.offer(for: sent, in: model.entries, never: model.neverSave, site: Self.site) else {
            return
        }
        let site = Self.site(login.origin.host() ?? "") ?? ""
        popover.show(
            PasswordSaveOffer(site: site, username: login.username, isUpdate: offer != .save) { [weak self] answer in
                self?.answer(answer, offer: offer, sent: sent, site: site)
            },
            // At the password field sent, as the suggestions are at theirs; the page's top when it is not known.
            at: login.frame.isEmpty ? CGRect(x: view.bounds.midX, y: 0, width: 1, height: 1) : login.frame,
            of: view,
            edge: .maxY
        )
    }

    /// A sign-up form's password field: a strong password made for the page (its rules, else its site's), filled into
    /// the password and its confirmation when clicked; saved after the form is sent.
    private func newPassword(for field: LoginField, in page: WebContent) -> AnyView? {
        let site = field.origin.host().flatMap { (try? PasswordManagerResources.bundled())?.passwordRules(for: $0) }
        let password = NewPassword.make(rules: NewPassword.rules(page: field.rules, site: site))
        return AnyView(
            StrongPasswordOffer(password: password) { [weak self] in
                self?.filling { _ = await page.fillNewPassword(password, for: field.origin) }
            }
        )
    }

    /// A one-time code's field: the codes of the site's entries that have one; the one clicked is filled as it is then.
    /// For HOTP entries, advances and saves the persisted counter immediately after filling (roadmap 0093 E / t102).
    private func codes(for field: LoginField, in page: WebContent) -> AnyView? {
        shown(CodeOffer.offered(model.entries, for: field.origin, site: Self.site)) { offers in
            CodeSuggestions(offers: offers) { [weak self] offer in
                let code = offer.field.code(at: Runtime.live.now())
                if let advancedURI = offer.field.advancingCounterURI {
                    self?.advanceHOTPCounter(in: offer.entry, newURI: advancedURI)
                }
                self?.filling { _ = await page.fillCode(code, for: field.origin) }
            }
        }
    }

    private func advanceHOTPCounter(in entry: VaultEntry, newURI: String) {
        guard let otpField = entry.sections.flatMap(\.fields).first(where: { $0.kind == .oneTimeCode }) else { return }
        var updated = entry
        updated.set(otpField.id, newURI)
        try? model.save(updated)
    }

    /// A card's field: the vault's cards; the one clicked is filled once the person has said it is them (Touch ID or the
    /// Mac's password, as Safari asks for a card), its security code with it (ADR-0094).
    private func cards(for field: LoginField, in page: WebContent) -> AnyView? {
        suggest(CardOffer.offered(model.entries), symbol: "creditcard.fill", entry: \.entry) { offer in
            "\u{2022}\u{2022}\u{2022}\u{2022} \(offer.lastFour)"
        } fill: { offer in
            guard await Self.isOwner(reason: "fill \(PasswordLook.title(offer.entry))") else { return }
            let values = offer.values
            let card = [
                "number": values.number, "name": values.name, "month": values.month, "year": values.year,
                "code": values.code
            ]
            _ = await page.fillCard(card, for: field.origin)
        }
    }

    /// A contact or address field: the vault's identities; the one clicked fills the form's contact and address fields.
    /// No Touch ID: what an identity holds is what the person gives every shop (Safari's contact AutoFill asks none).
    private func identities(for field: LoginField, in page: WebContent) -> AnyView? {
        suggest(IdentityOffer.offered(model.entries), symbol: "person.crop.circle.fill", entry: \.entry, \.detail) {
            offer in _ = await page.fillIdentity(offer.values, for: field.origin)
        }
    }

    /// `offers` as rows (`EntrySuggestions`), none when there are none; the one clicked closes the popover and `fill`s.
    private func suggest<Offer>(
        _ offers: [Offer],
        symbol: String,
        entry: KeyPath<Offer, VaultEntry>,
        _ detail: @escaping (Offer) -> String,
        fill: @escaping @MainActor (Offer) async -> Void
    ) -> AnyView? {
        let rows = offers.map { EntrySuggestions.Offer(entry: $0[keyPath: entry], detail: detail($0)) }
        return shown(rows) { rows in
            EntrySuggestions(offers: rows, symbol: symbol) { [weak self] chosen in
                guard let offer = offers.first(where: { $0[keyPath: entry].id == chosen.id }) else { return }
                self?.filling { await fill(offer) }
            }
        }
    }

    /// The person at the Mac says it is them: Touch ID, else its password.
    static func isOwner(reason: String) async -> Bool {
        (try? await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) ?? false
    }

    private func fill(_ entry: VaultEntry, in page: WebContent, for origin: URL) {
        guard let credentials = LoginMatch.credentials(of: entry) else { return popover.close() }
        filling { _ = await page.fill(username: credentials.username, password: credentials.password, for: origin) }
    }

    /// `content` of `items`; none when there are none.
    private func shown<Item>(_ items: [Item], _ content: ([Item]) -> some View) -> AnyView? {
        items.isEmpty ? nil : AnyView(content(items))
    }

    /// What a click on a suggestion does: the popover goes, then the page is filled.
    private func filling(_ work: @escaping @MainActor () async -> Void) {
        popover.close()
        Runtime.live.task { @MainActor in await work() }
    }

    private func answer(_ answer: PasswordSaveOffer.Answer, offer: LoginSave.Offer, sent: SentLoginValues, site: String)
    {
        popover.close()
        switch (answer, offer) {
            case (.save, .save): try? model.save(LoginSave.entry(for: sent, site: Self.site))
            case (.save, .update(let id)):
                guard let entry = model.entries.first(where: { $0.id == id }) else { return }
                try? model.save(LoginSave.updated(entry, password: sent.password))
            case (.never, _): try? model.setNeverSave(site)
            case (.notNow, _): return
        }
    }
}
