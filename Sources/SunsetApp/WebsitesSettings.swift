import SunsetConfig
import SunsetShell
import SunsetWeb
import SwiftUI

/// Settings > Web > Websites (web step g), rows of their section (the owner's note n13): for each permission, what a site not
/// yet answered gets, and under it the sites answered, each changeable or removed (the default applies to it again).
struct WebsitesSettings: View {
    @Binding var defaults: [String: Configuration.Web.PermissionDefault]
    private let store = SitePermissions.shared

    var body: some View {
        ForEach(SitePermission.allCases, id: \.self) { permission in
            LabeledContent {
                Picker(permission.title, selection: defaultBinding(permission)) {
                    ForEach(Configuration.Web.PermissionDefault.allCases, id: \.self) {
                        Text($0.rawValue.capitalized).tag($0)
                    }
                }
                .labelsHidden()
                .fixedSize()
            } label: {
                Label(permission.title, systemImage: permission.symbol)
            }
            ForEach(store.sites(for: permission), id: \.host) { site in
                SiteRuleRow(host: site.host) {
                    Picker(site.host, selection: siteBinding(permission, site.host)) {
                        ForEach(PermissionAnswer.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                } remove: {
                    store.set(nil, permission, for: site.host)
                }
            }
        }
    }

    private func defaultBinding(_ permission: SitePermission) -> Binding<Configuration.Web.PermissionDefault> {
        Binding(
            get: { defaults[permission.rawValue] ?? .ask },
            set: { defaults[permission.rawValue] = $0 }
        )
    }

    private func siteBinding(_ permission: SitePermission, _ host: String) -> Binding<PermissionAnswer> {
        Binding(get: { store.answer(permission, for: host) }, set: { store.set($0, permission, for: host) })
    }
}
