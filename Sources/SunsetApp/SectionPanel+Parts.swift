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

    /// Escape in the search field: the search is cleared; with none, the Library goes back to the tabs and the pane has the
    /// keyboard again.
    private func escape() {
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
                Menu {
                    Picker("Order", selection: sortBinding) {
                        ForEach(DocumentSort.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } label: {
                    SidebarSymbol(name: "arrow.up.arrow.down", filled: false)
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .menuIndicator(.hidden)
                .foregroundStyle(.secondary)
                .fixedSize()
                .frame(width: buttons.metrics.size.width, height: buttons.metrics.size.height)
                .help("Order of the documents")
                .accessibilityLabel("Order of the documents")
                SidebarIconButton(symbol: "plus", help: "New Document") { tabs.newDocument() }
                    .disabled(!tabs.shelf.available())
                    .accessibilityLabel("New Document")
            case .downloads:
                Button("Clear") { DownloadCenter.shared.clear() }
                    .buttonStyle(.borderless)
                    .font(Design.Text.detail)
                    .disabled(DownloadCenter.shared.items.allSatisfy { $0.state == .running })
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

    /// The switch between the sections, at the foot of the panel opposite the tabs (the owner's choice B6).
    @ViewBuilder var foot: some View {
        if place == .opposite {
            SectionSwitch(selection: Binding(get: { section }, set: { tabs.sections.opposite = $0 }))
                .environment(\.sidebarButtonMetrics, buttons.metrics)
                .padding(.horizontal, buttons.gap)
                .padding(.bottom, buttons.bottom)
        }
    }

    /// Rows that scroll up under the top fade out over it, and under the switch at the foot.
    var fade: some View {
        VStack(spacing: 0) {
            LinearGradient(gradient: .eased(from: .clear, to: .black), startPoint: .top, endPoint: .bottom)
                .frame(height: max(listTop - Design.Space.xs, 0))
            Color.black
            if place == .opposite {
                LinearGradient(gradient: .eased(from: .black, to: .clear), startPoint: .top, endPoint: .bottom)
                    .frame(height: footInset + buttons.margin)
            }
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
