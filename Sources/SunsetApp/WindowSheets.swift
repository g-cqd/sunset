import SunsetShell
import SwiftUI

/// The sheets a window opens from its menus: Clear History, Import from Another Browser.
struct WindowSheets: ViewModifier {
    let tabs: TabsModel

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: Binding(get: { tabs.clearingHistory }, set: { tabs.clearingHistory = $0 })) {
                ClearHistorySheet()
            }
            .sheet(isPresented: Binding(get: { tabs.importing }, set: { tabs.importing = $0 })) {
                ImportSheet(tabs: tabs)
            }
    }
}
