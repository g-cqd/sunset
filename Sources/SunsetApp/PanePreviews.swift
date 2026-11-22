import SunsetConfig
import SunsetShell
import SwiftUI

/// The tabs' previews of a window, drawn over everything in it, a floating sidebar included (they were drawn by the
/// pane area, which the floating sidebar covers), in the pane area's place.
struct PanePreviews: View {
    let tabs: TabsModel
    let layout: Configuration.Layout
    let sidebarOnRight: Bool
    let kinds: PreviewKinds

    var body: some View {
        GeometryReader { proxy in
            if let area = tabs.paneAreaFrame {
                let here = proxy.frame(in: .global)
                TabPreviewHost(tabs: tabs, layout: layout, area: area, sidebarOnRight: sidebarOnRight, kinds: kinds)
                    .frame(width: area.width, height: area.height)
                    .offset(x: area.minX - here.minX, y: area.minY - here.minY)
            }
        }
        .allowsHitTesting(false)
    }
}
