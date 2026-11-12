import SunsetConfig
import SunsetShell
import SwiftUI

/// What a window shows over its content when asked: the command bar, the rename dialog, the choice of kind for a new tab, a kept terminal's command.
struct WindowDialogs: ViewModifier {
    let tabs: TabsModel
    let layout: Configuration.Layout

    func body(content: Content) -> some View {
        content
            .overlay { CommandBarView(tabs: tabs, layout: layout).modifier(RenameTabAlert(tabs: tabs)) }
            .sheet(isPresented: Binding(get: { tabs.choosingKind }, set: { tabs.choosingKind = $0 })) {
                KindChooser(tabs: tabs)
            }
            .sheet(
                isPresented: Binding(get: { tabs.editingCommand != nil }, set: { if !$0 { tabs.editingCommand = nil } })
            ) {
                if let entry = tabs.editingCommand { CommandSheet(tabs: tabs, entry: entry) }
            }
            .sheet(isPresented: Binding(get: { tabs.clearingHistory }, set: { tabs.clearingHistory = $0 })) {
                ClearHistorySheet()
            }
    }
}
