import SunsetMetrics
import SunsetPane
import SwiftUI

/// The documents among the tabs (roadmap 0030 step ST-5, the owner's layout A): a small heading with a chevron that folds it
/// and a + that makes a document, the documents under it in the chosen order, then a thin line above the window's tabs. A
/// click opens a document in place: its row is then its tab, with a faint fill and a minus that closes the pane; the
/// document stays listed. The heading is there with no document yet.
struct DocumentsHeading: View {
    let tabs: TabsModel
    let settings: ShellSettings
    let layout: ShellSettings.Layout

    var body: some View {
        heading
        ForEach(tabs.shelfRows(sort: settings.sidebar.documentSort)) { row in
            self.row(row)
                .onTapGesture { tabs.open(document: row.id) }
                .onDrag { tabs.itemProvider(for: .document(row.id)) }
                .contextMenu { menu(row) }
        }
        Rectangle()
            .fill(.primary.opacity(layout.hairlineOpacity * Design.Line.stronger))
            .frame(height: max(layout.hairlineWidth, 0.5))
            .padding(.horizontal, layout.tabPaddingLeading)
            .frame(height: Design.Space.s)
    }

    private var folded: Bool { tabs.sections.documentsFolded }

    private var heading: some View {
        HStack(spacing: Design.Space.xs) {
            Button {
                tabs.sections.documentsFolded.toggle()
            } label: {
                HStack(spacing: Design.Space.xs) {
                    Text("Documents").font(Design.Text.detail.weight(.semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: Design.Symbol.badge, weight: .bold))
                        .rotationEffect(.degrees(folded ? -90 : 0))
                }
                .foregroundStyle(.secondary)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .help(folded ? "Show the documents" : "Hide the documents")
            .accessibilityLabel(folded ? "Documents, folded" : "Documents")
            Spacer(minLength: 0)
            Button {
                tabs.newDocument()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: Design.Symbol.badge, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: layout.closeButtonSize, height: layout.closeButtonSize)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(!tabs.shelf.available())
            .help(tabs.shelf.available() ? "New Document" : "Nothing can be kept in this run: see Settings, Storage")
            .accessibilityLabel("New Document")
        }
        .padding(.leading, layout.tabPaddingLeading)
        .padding(.trailing, layout.tabPaddingTrailing)
        .frame(height: layout.closeButtonSize)
        .animation(layout.smooth, value: folded)
    }

    private func row(_ row: ShelfRow) -> some View {
        SidebarRow(
            model: row.item.flatMap { item in
                item.panes.first { tabs.document(in: $0) == row.id }.flatMap { tabs.contents[$0] }
            },
            selected: row.item.map { tabs.isSelected($0.id) } ?? false,
            armed: row.item.map { tabs.isCloseArmed($0.id) } ?? false,
            // Open, its title is the pane's (what is typed shows before it is saved); else what the store last kept.
            name: row.item == nil ? row.document.title : nil,
            icon: row.document.kind == .markdown ? nil : .symbol(row.document.kind.symbol),
            saved: .document(stored: row.id),
            showIcon: settings.tabs.bar.showIcon,
            showTitle: true,
            showDirectory: false,
            showProgress: false,
            layout: layout,
            button: .closeDocument,
            hasButton: row.item != nil,
            open: row.item != nil,
            compact: true,
            close: { tabs.unload(document: row.id) }
        )
    }

    @ViewBuilder
    private func menu(_ row: ShelfRow) -> some View {
        Button("Open") { tabs.open(document: row.id) }
        Button("Open in New Tab") {
            tabs.openTab(
                document: row.id,
                at: (tabs.workspace.selectedIndex ?? tabs.workspace.count - 1) + 1,
                show: true
            )
        }
        if row.item != nil { Button("Close") { tabs.unload(document: row.id) } }
        Divider()
        Button("Delete", role: .destructive) { tabs.delete(document: row.id) }
    }
}
