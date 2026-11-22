import AppKit
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

    func loginField(focused field: LoginField, in page: WebContent) {
        guard isOn, field.role != .newPassword, let view = page.webView else { return popover.close() }
        let logins = LoginMatch.offered(model.entries, for: field.origin, site: Self.site)
        guard !logins.isEmpty else { return popover.close() }
        popover.show(
            PasswordSuggestions(logins: logins) { [weak self] entry in
                self?.fill(entry, in: page)
            },
            at: field.frame,
            of: view,
            edge: .maxY,
            suggestions: true
        )
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

    private func fill(_ entry: VaultEntry, in page: WebContent) {
        popover.close()
        guard let credentials = LoginMatch.credentials(of: entry) else { return }
        Runtime.live.task { @MainActor in
            _ = await page.fill(username: credentials.username, password: credentials.password)
        }
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
