import SunsetConfig
import SunsetMetrics
import SunsetPane
import SunsetShell
import SunsetWeb
import SwiftUI

/// The calls to action under the sidebar's field (roadmap 0035 I): the questions of the pages of the shown tab (what a site
/// wants: Don't Allow, Allow Once, Allow), and what macOS must allow Sunset for a site allowed (`SystemAsk`). Nothing when
/// there is nothing to answer.
struct SidebarNotices: View {
    let tabs: TabsModel
    let layout: Configuration.Layout

    /// The pages of the shown tab waiting for an answer.
    private var requests: [(page: WebContent, request: PermissionRequest)] {
        (tabs.shownItem?.panes ?? [])
            .compactMap { pane in
                guard let page = tabs.content(pane) as? WebContent, let request = page.permissionRequest else {
                    return nil
                }
                return (page, request)
            }
    }

    var body: some View {
        VStack(spacing: layout.tabSpacing) {
            ForEach(requests, id: \.request.id) { item in pageCard(item.request, store: item.page.permissions) }
            ForEach(SystemAuthorizations.shared.asks) { ask in systemCard(ask) }
        }
        .animation(layout.smooth, value: requests.map(\.request.id))
    }

    private func card(symbols: [String], text: String, @ViewBuilder buttons: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Design.Space.s) {
            HStack(alignment: .firstTextBaseline, spacing: Design.Space.s) {
                ForEach(symbols, id: \.self) { Image(systemName: $0).foregroundStyle(.secondary) }
                Text(text).font(Design.Text.detail).fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: Design.Space.xs) {
                Spacer(minLength: 0)
                buttons()
            }
            .controlSize(.small)
        }
        .padding(Design.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: layout.tabRadius, style: .continuous)
                .fill(Color.primary.opacity(Design.Fill.open))
        )
        .transition(.opacity)
    }

    private func pageCard(_ request: PermissionRequest, store: SitePermissions) -> some View {
        card(symbols: request.permissions.map(\.symbol), text: request.sentence) {
            if request.unavailable {
                Button("OK") { request.choose(.deny, keepIn: store) }
            } else {
                Button("Don't Allow") { request.choose(.deny, keepIn: store) }
                Button("Once") { request.choose(.allowOnce, keepIn: store) }.help("Allow Once")
                Button("Allow") { request.choose(.allow, keepIn: store) }.buttonStyle(.borderedProminent)
            }
        }
    }

    private func systemCard(_ ask: SystemAsk) -> some View {
        card(symbols: [ask.need.symbol], text: ask.sentence) {
            Button(ask.button) { SystemAuthorizations.shared.act(on: ask) }
        }
    }
}
