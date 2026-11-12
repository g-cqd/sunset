import SunsetConfig
import SunsetWeb
import SwiftUI

/// Settings > Web > Websites (web step g): for each permission, what a site not yet answered gets, and the sites answered, each changeable or
/// removed (the default applies to it again).
struct WebsitesSettings: View {
    @Binding var defaults: [String: Configuration.Web.PermissionDefault]
    private let store = SitePermissions.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Websites").font(.headline)
            ForEach(SitePermission.allCases, id: \.self) { permission in section(permission) }
        }
    }

    private func section(_ permission: SitePermission) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(permission.title, systemImage: permission.symbol)
                Spacer()
                Picker("Other sites", selection: defaultBinding(permission)) {
                    ForEach(Configuration.Web.PermissionDefault.allCases, id: \.self) {
                        Text($0.rawValue.capitalized).tag($0)
                    }
                }
                .fixedSize()
            }
            ForEach(store.sites(for: permission), id: \.host) { site in
                HStack {
                    Text(site.host).foregroundStyle(.secondary)
                    Spacer()
                    Picker("", selection: siteBinding(permission, site.host)) {
                        Text("Allow").tag(PermissionAnswer.allow)
                        Text("Deny").tag(PermissionAnswer.deny)
                    }
                    .labelsHidden()
                    .fixedSize()
                    Button {
                        store.set(nil, permission, for: site.host)
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.borderless)
                    .help("Remove: the default applies again")
                }
                .padding(.leading, 26)
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
