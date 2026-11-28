import AppKit
import LocalAuthentication
import SunsetAppCore
import SunsetConfig
import SunsetCredentials
import SunsetRuntime
import SunsetSiteData
import SunsetWeb
import SwiftUI

/// Filling and saving in pages (roadmap 0094, ADR-0094), in a borderless panel with concentric corners: when a sign-in,
/// email or one-time code field takes the keyboard and the vault has logins for the page's site, the panel under the
/// field lists them without taking keyboard focus; when the vault is locked and `passwords.offerUnlock` is on, it offers
/// an inline unlock row and immediately shows matching entries once unlocked.
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

    private var isEnabled: Bool {
        AppConfiguration.shared.configuration.features.credentials
    }

    private var isOn: Bool {
        isEnabled && model.state == .unlocked
    }

    /// A host's site (`LoginSite`), by the Public Suffix List; from any thread (an import reads off the main one).
    nonisolated static func site(_ host: String) -> String? {
        LoginSite.of(host) { (try? PublicSuffixList.bundled())?.registrableDomain(of: $0) }
    }

    /// True when `origin` is plain `http://` on a non-loopback host (roadmap 0094 / t103).
    static func isInsecure(_ origin: URL) -> Bool {
        guard origin.scheme?.lowercased() == "http" else { return false }
        let host = (origin.host() ?? "").lowercased()
        return host != "localhost" && host != "127.0.0.1" && host != "::1" && !host.hasSuffix(".localhost")
    }

    func loginField(focused field: LoginField, in page: WebContent) {
        guard let view = page.webView else { return popover.close() }
        let config = AppConfiguration.shared.configuration
        if PasswordsModel.offersUnlock(
            enabled: config.features.credentials,
            state: model.state,
            offerSetting: config.passwords.offerUnlock,
            isPrivate: page.isPrivate,
            role: field.role
        ) {
            let unlockView = VaultUnlockOffer(
                model: model,
                requestKeyFocus: { [weak self] in self?.popover.makeKey() },
                unlocked: { [weak self, weak page] in
                    guard let self, let page else { return }
                    self.popover.close()
                    self.loginField(focused: field, in: page)
                }
            )
            popover.show(unlockView, at: field.frame, of: view, edge: .maxY, suggestions: true)
            return
        }
        guard isOn else { return popover.close() }
        let content: AnyView? =
            switch field.role {
                case .newPassword: newPassword(for: field, in: page)
                case .oneTimeCode: codes(for: field, in: page)
                case .card: cards(for: field, in: page)
                case .identity: identities(for: field, in: page)
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

    /// A sign-in form shown as its page loads: filled with the site's one login, saved for the page's very origin, when
    /// the person allows it (`passwords.autoFill`, off unless asked) and the page is https; else nothing until a click.
    func loginFormShown(_ field: LoginField, in page: WebContent) {
        guard isOn, AppConfiguration.shared.configuration.passwords.autoFill,
            let entry = LoginMatch.autoFilled(model.entries, for: field.origin, site: Self.site),
            let credentials = LoginMatch.credentials(of: entry)
        else { return }
        Runtime.live.task { @MainActor in
            _ = await page.fillOnLoad(username: credentials.username, password: credentials.password, for: field.origin)
        }
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
            at: login.frame.isEmpty ? CGRect(x: view.bounds.midX, y: 0, width: 1, height: 1) : login.frame,
            of: view,
            edge: .maxY
        )
    }

    private func newPassword(for field: LoginField, in page: WebContent) -> AnyView? {
        let site = field.origin.host().flatMap { (try? PasswordManagerResources.bundled())?.passwordRules(for: $0) }
        let password = NewPassword.make(rules: NewPassword.rules(page: field.rules, site: site))
        return AnyView(
            StrongPasswordOffer(password: password) { [weak self] in
                self?.filling { _ = await page.fillNewPassword(password, for: field.origin) }
            }
        )
    }

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

    private func identities(for field: LoginField, in page: WebContent) -> AnyView? {
        suggest(IdentityOffer.offered(model.entries), symbol: "person.crop.circle.fill", entry: \.entry, \.detail) {
            offer in _ = await page.fillIdentity(offer.values, for: field.origin)
        }
    }

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

    static func isOwner(reason: String) async -> Bool {
        (try? await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) ?? false
    }

    private func fill(_ entry: VaultEntry, in page: WebContent, for origin: URL) {
        guard let credentials = LoginMatch.credentials(of: entry) else { return popover.close() }
        filling { _ = await page.fill(username: credentials.username, password: credentials.password, for: origin) }
    }

    private func shown<Item>(_ items: [Item], _ content: ([Item]) -> some View) -> AnyView? {
        items.isEmpty ? nil : AnyView(content(items))
    }

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
