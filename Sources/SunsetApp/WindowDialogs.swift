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
                            // Nothing beneath takes the pointer: no click, scroll or hover; a click closes the bar.
                            CommandBarBackdrop()
                                .overlay { PointerShieldView { tabs.bar = nil } }
                                .transition(.opacity)
                        }
                        addressBar(area?.card)
                            .frame(width: panes.width, height: panes.height)
                            .offset(x: panes.minX, y: panes.minY)
                        if tabs.bar?.inSidebar == true, let field = tabs.sidebarField {
                            // In the sidebar's field, its size, the rows under it.
                            let origin = proxy.frame(in: .global).origin
                            CommandBarView(tabs: tabs, layout: layout, anchor: field.size)
                                .modifier(RenameTabAlert(tabs: tabs))
                                .offset(x: field.minX - origin.x, y: field.minY - origin.y)
                        } else {
                            // Centred over the panes, not the window (owner, 2026-11-13).
                            CommandBarView(
                                tabs: tabs,
                                layout: layout,
                                room: CGSize(width: panes.width, height: proxy.size.height)
                            )
                            .modifier(RenameTabAlert(tabs: tabs))
                            .frame(width: panes.width, height: proxy.size.height, alignment: .top)
                            .offset(x: panes.minX)
                        }
                    }
                }
            }
            .modifier(SpaceDialogs(tabs: tabs))
            .sheet(
                isPresented: Binding(get: { tabs.editingCommand != nil }, set: { if !$0 { tabs.editingCommand = nil } })
            ) {
                if let entry = tabs.editingCommand { CommandSheet(tabs: tabs, entry: entry) }
            }
            .modifier(WindowSheets(tabs: tabs))
            .sheet(
                isPresented: Binding(
                    get: { QuitGate.shared.isAsking(tabs) },
                    set: { if !$0, QuitGate.shared.isAsking(tabs) { QuitGate.shared.answer(quit: false) } }
                )
            ) {
                QuitSheet(gate: .shared)
            }
            .sheet(
                isPresented: Binding(
                    get: { tabs.unsavedQuestion != nil },
                    set: { if !$0 { tabs.answerUnsaved(.cancel) } }
                )
            ) {
                if let question = tabs.unsavedQuestion { UnsavedSheet(tabs: tabs, question: question) }
            }
    }
}
