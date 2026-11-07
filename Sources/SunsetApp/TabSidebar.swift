import AppKit
import Foundation
import SunsetConfig
import SunsetHost
import SwiftUI

/// The sidebar: the tabs of the window, listed vertically (the same `TabList` the built-in bar shows). A click selects a tab, a button closes it, a drag
/// reorders them.
struct TabSidebar: View {
    let tabs: TabsModel
    let settings: Configuration

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(tabs.list.tabs) { tab in
                    let selected = tab.id == tabs.list.selectedID
                    HStack {
                        TabLabel(
                            model: tabs.models[tab.id],
                            showTitle: settings.tabs.bar.showTitle,
                            showDirectory: settings.tabs.bar.showDirectory,
                            showProgress: settings.tabs.bar.showProgress
                        )
                        Spacer(minLength: 0)
                        Button {
                            tabs.close(tab.id)
                        } label: {
                            Image(systemName: "xmark").font(.caption2)
                        }
                        .buttonStyle(.borderless)
                        .help("Close Tab")
                    }
                    .padding(.vertical, 2)
                    .listRowBackground(selected ? Color.accentColor.opacity(0.25) : Color.clear)
                    .contentShape(.rect)
                    .onTapGesture { tabs.select(tab.id) }
                    .draggable(tab.id.uuidString)
                    .dropDestination(for: String.self) { items, _ in
                        guard let text = items.first, let id = UUID(uuidString: text),
                            let index = tabs.list.tabs.firstIndex(where: { $0.id == tab.id })
                        else { return false }
                        tabs.move(id, to: index)
                        return true
                    }
                    .contextMenu {
                        Button("Close Tab") { tabs.close(tab.id) }
                        Button("Close Other Tabs") {
                            for other in tabs.list.tabs where other.id != tab.id { tabs.close(other.id) }
                        }
                        .disabled(tabs.list.count < 2)
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            Divider().opacity(0.4)
            Button {
                tabs.newTab()
            } label: {
                Label("New Tab", systemImage: "plus")
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
        .background { SidebarBackdrop(look: SidebarLook(settings)) }
    }
}
