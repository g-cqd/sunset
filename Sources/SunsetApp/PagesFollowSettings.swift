import Foundation
import SunsetConfig
import SunsetShell
import SunsetWeb
import SwiftUI

/// The pages of a window take the web settings again when they change: the engine, suggestions and the http fallback apply to open pages at once.
struct PagesFollowSettings: ViewModifier {
    let tabs: TabsModel
    let web: Configuration.Web

    func body(content: Content) -> some View {
        content.onChange(of: web.zoomScope, initial: true) { _, scope in
            let path = SessionLocation.zoomPath(
                environment: ProcessInfo.processInfo.environment,
                home: NSHomeDirectory()
            )
            let wanted = scope == .site ? path : nil
            if SiteZoom.shared.path != wanted || scope == .site && SiteZoom.shared.path == nil {
                SiteZoom.shared.path = wanted
            }
        }
        .onChange(of: web) { _, now in
            AppDownloads.apply(now)
            let settings = PaneContentKinds.webSettings
            for page in tabs.allPages {
                page.settings = settings
                page.applyZoom()
            }
        }
    }
}
