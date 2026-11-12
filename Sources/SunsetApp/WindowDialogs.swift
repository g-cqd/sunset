import SunsetConfig
import SunsetShell
import SwiftUI

/// What a window shows over its content when asked: the command bar, the rename dialog, the choice of kind for a new tab, a kept terminal's command.
struct WindowDialogs: ViewModifier {
    let tabs: TabsModel
    let layout: Configuration.Layout
    /// The window's address bar over the focused pane (its card given): drawn here, above the command bar's backdrop, so that the
    /// backdrop does not blur it (owner, 2026-11-13).
    let addressBar: (PaneCardShape?) -> AnyView

    func body(content: Content) -> some View {
        content
            .overlayPreferenceValue(PaneCardShape.Key.self) { area in
                GeometryReader { proxy in
                    let panes = area.map { proxy[$0.bounds] } ?? CGRect(origin: .zero, size: proxy.size)
                    ZStack(alignment: .topLeading) {
                        if tabs.bar != nil {
                            CommandBarBackdrop()
                                .contentShape(.rect)
                                .onTapGesture { tabs.bar = nil }
                                .transition(.opacity)
                        }
                        addressBar(area?.card)
                            .frame(width: panes.width, height: panes.height)
                            .offset(x: panes.minX, y: panes.minY)
                        // Centred over the panes, not the window (owner, 2026-11-13).
                        CommandBarView(tabs: tabs, layout: layout)
                            .modifier(RenameTabAlert(tabs: tabs))
                            .frame(width: panes.width, height: proxy.size.height, alignment: .top)
                            .offset(x: panes.minX)
                    }
                }
            }
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
            .sheet(
                isPresented: Binding(
                    get: { QuitGate.shared.isAsking(tabs) },
                    set: { if !$0, QuitGate.shared.isAsking(tabs) { QuitGate.shared.answer(quit: false) } }
                )
            ) {
                QuitSheet(gate: .shared)
            }
    }
}
