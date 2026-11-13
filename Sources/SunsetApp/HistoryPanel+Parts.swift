import AemiSDR
import SunsetMetrics
import SunsetShell
import SwiftUI

extension HistoryPanel {
    /// The title and the hide button, centred on the window buttons' row as the sidebar's pin is; then the search field.
    var top: some View {
        VStack(spacing: 0) {
            HStack {
                Text("History").font(Design.Text.body.weight(.semibold))
                Spacer()
                SidebarIconButton(symbol: "sidebar.trailing", help: "Hide History (Cmd-Y)") {
                    tabs.showsHistory = false
                }
                .environment(\.sidebarButtonMetrics, buttonMetrics)
            }
            .padding(.leading, layout.tabPaddingLeading)
            .padding(.top, header.dockedButtonInset)
            .frame(height: header.height, alignment: .top)
            TextField("Search History", text: $query).textFieldStyle(.plain).fieldSurface()
        }
        .padding(.horizontal, layout.tabSideInset)
    }

    /// The sidebar's docked pin button.
    private var buttonMetrics: SidebarButtonMetrics {
        SidebarButtonMetrics(
            size: CGSize(width: header.dockedButtonSize, height: header.dockedButtonHeight),
            radius: layout.sidebarButtonRadius,
            smooth: layout.smooth
        )
    }

    /// A day, as the sidebar's section titles.
    func dayTitle(_ title: String) -> some View {
        Text(title)
            .font(Design.Text.detail.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, layout.tabPaddingLeading)
            .padding(.top, Design.Space.m)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Rows that scroll up under the top fade out over it.
    var fade: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: max(listTop - Design.Space.xs, 0))
            Color.black
        }
    }

    /// And blur out there, as at the sidebar's ends (research/blur).
    var topBlur: some View {
        let solid = listTop * Design.Blur.listSolidShare
        return Color.clear
            .frame(height: listTop)
            .padding(.horizontal, -Design.Blur.listBleed)
            .blurUnder(
                .top,
                solid: solid,
                fade: listTop - solid + Design.Blur.listOverhang,
                radius: Design.Blur.listRadius
            )
            .allowsHitTesting(false)
    }
}
