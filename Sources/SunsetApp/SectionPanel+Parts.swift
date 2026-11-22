import AemiSDR
import SunsetConfig
import SunsetMetrics
import SunsetShell
import SunsetWeb
import SwiftUI

extension SectionPanel {
    /// The title with what the section offers, then the search field.
    var top: some View {
        SectionHeading(top: topMeasures, title: section.title) {
            actions
            if place == .opposite {
                SidebarIconButton(symbol: "sidebar.trailing", help: "Hide \(section.title) (Cmd-Y)") {
                    tabs.showsHistory = false
                }
            }
        } field: {
            TextField("Search \(section.title)", text: $query).textFieldStyle(.plain).fieldSurface()
                .focused($searching)
                .onExitCommand { escape() }
        }
    }

    /// Escape in the search field or on the list: the search is cleared; with none, the Library goes back to the tabs and
    /// the pane has the keyboard again.
    func escape() {
        guard query.isEmpty else {
            query = ""
            return
        }
        guard place == .library else { return }
        tabs.sections.closeLibrary()
        if let pane = tabs.shownPane { tabs.focus(pane) }
    }

    /// What the section's title row offers: the order and a new document; clearing the downloads.
    @ViewBuilder private var actions: some View {
        switch section {
            case .documents:
                SectionMenuButton(
                    symbol: "arrow.up.arrow.down",
                    label: "Order of the documents",
                    size: buttons.metrics.size
                ) {
                    Picker("Order", selection: sortBinding) {
                        ForEach(DocumentSort.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                SidebarIconButton(symbol: "plus", help: "New Document") { tabs.newDocument() }
                    .disabled(!tabs.shelf.available())
                    .accessibilityLabel("New Document")
            case .downloads:
                Button("Clear") { DownloadCenter.shared.clear() }
                    .buttonStyle(.borderless)
                    .font(Design.Text.detail)
                    .disabled(DownloadCenter.shared.items.allSatisfy { $0.state == .running })
            case .passwords:
                PasswordsActions(model: AppPasswords.model, tabs: tabs, size: buttons.metrics.size)
            case .history, .tabs, .settings:
                EmptyView()
        }
    }

    private var sortBinding: Binding<DocumentSort> {
        Binding(
            get: { sort },
            set: { new in
                AppConfiguration.shared.update {
                    $0.sidebar.documentSort = Configuration.Sidebar.DocumentSort(rawValue: new.rawValue) ?? .changed
                }
            }
        )
    }

    /// The switch between the sections, at the foot of the panel opposite the tabs.
    @ViewBuilder var foot: some View {
        if place == .opposite {
            SectionSwitch(
                sections: SidebarSection.panel(for: tabs.scopes),
                selection: Binding(get: { section }, set: { tabs.sections.opposite = $0 })
            )
            .environment(\.sidebarButtonMetrics, buttons.metrics)
            .padding(.horizontal, buttons.gap)
            .padding(.bottom, buttons.bottom)
        }
    }

    /// Rows that scroll up are gone under the title and the search field, and fade out just below them (under the field
    /// they were unreadable; an alpha mask, no blur); and under the switch at the foot.
    var fade: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: max(listTop - Design.Space.xs, 0))
            LinearGradient(
                gradient: .end(from: .clear, to: .black, fading: fadesEnds),
                startPoint: .top,
                endPoint: .bottom
            )
            // As tall as the rows are scrolled, up to its full height: rows at rest are untouched.
            .frame(height: min(scrolledBy, Design.Space.xl))
            Color.black
            if place == .opposite {
                LinearGradient(
                    gradient: .end(from: .black, to: .clear, fading: fadesEnds),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: footInset + buttons.margin)
            }
        }
    }
}
