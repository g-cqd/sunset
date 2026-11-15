import Foundation
import SunsetMetrics
import SunsetPane
import SwiftUI
import Testing

@testable import SunsetShell

/// The sections of the sidebars as built (roadmap 0031, 0030 step ST-5): the Documents heading among the tabs, the switch at
/// the foot of the opposite panel, the Library's rail. The real views, drawn off screen.
extension DesignCatalogTests {
    /// A window's tabs with two documents kept, the first open in place (`open`) and edited.
    private func shelfHarness(open: Bool, folded: Bool = false, none: Bool = false) -> TabsHarness {
        let harness = TabsHarness()
        let ids = [UUID(), UUID(), UUID()]
        let day = 86_400.0
        let documents = [
            ShelfDocument(id: ids[0], title: "Harbour notes", kind: .markdown, created: .now, modified: .now),
            ShelfDocument(id: ids[1], title: "Login flow", kind: .diagram, created: .now, modified: .now - day),
            ShelfDocument(id: ids[2], title: "Untitled", kind: .text, created: .now, modified: .now - 9 * day)
        ]
        harness.tabs.shelf.available = { true }
        harness.tabs.shelf.list = { none ? [] : documents }
        harness.tabs.newTab()
        harness.made.last?.title = "fish"
        harness.made.last?.glyphValue = .symbol("terminal")
        if open {
            harness.tabs.open(document: ids[0])
            harness.made.last?.title = "Harbour notes"
            harness.made.last?.glyphValue = .symbol("doc.text")
            harness.made.last?.isEdited = true
        }
        harness.tabs.sections.documentsFolded = folded
        return harness
    }

    private func builtSidebar(_ harness: TabsHarness) -> AnyView {
        let settings = ShellSettings()
        return AnyView(
            VStack(spacing: settings.layout.tabSpacing) {
                DocumentsHeading(tabs: harness.tabs, settings: settings, layout: settings.layout)
                ForEach(harness.tabs.listedItems(shelf: true)) { item in
                    SidebarRow(
                        model: harness.tabs.contents[item.focused],
                        selected: harness.tabs.isSelected(item.id),
                        showIcon: true,
                        showTitle: true,
                        showDirectory: false,
                        showProgress: false,
                        layout: settings.layout
                    ) {}
                }
            }
            .padding(4).background(Color(white: 0.09))
        )
    }

    private var builtButtons: SidebarButtons { SidebarButtons(layout: LayoutMetrics(), margin: 4, panelRadius: nil) }

    private func builtSwitch(_ section: SidebarSection) -> AnyView {
        AnyView(
            SectionSwitch(selection: .constant(section))
                .environment(\.sidebarButtonMetrics, builtButtons.metrics)
                .padding(4).background(Color(white: 0.09))
        )
    }

    private func builtRail(_ section: SidebarSection) -> AnyView {
        AnyView(
            SectionRail(selection: section, buttons: builtButtons) { _ in }
                .frame(height: 230)
                .padding(.horizontal, 4).background(Color(white: 0.09))
        )
    }

    var sectionsBuilt: CatalogSheet {
        CatalogSheet(
            title: "The sections of the sidebars, as built (0031, ST-5)",
            note:
                "The Documents heading among the tabs: a document's row is its tab while it is open (a faint fill, the edited "
                + "mark at its end, a minus under the pointer). The switch at the foot of the panel opposite the tabs. The "
                + "Library's rail: Tabs, Documents, History, Downloads, and the way back at its foot.",
            columns: [
                .init(
                    title: "Documents among the tabs",
                    examples: [
                        .init(label: "none open", view: builtSidebar(shelfHarness(open: false))),
                        .init(label: "one open, edited", view: builtSidebar(shelfHarness(open: true))),
                        .init(label: "folded", view: builtSidebar(shelfHarness(open: false, folded: true))),
                        .init(label: "no document yet", view: builtSidebar(shelfHarness(open: false, none: true)))
                    ]
                ),
                .init(
                    title: "The opposite panel's switch",
                    examples: [
                        .init(label: "History", view: builtSwitch(.history)),
                        .init(label: "Documents", view: builtSwitch(.documents)),
                        .init(label: "Downloads", view: builtSwitch(.downloads))
                    ]
                ),
                .init(
                    title: "The Library's rail",
                    examples: [
                        .init(label: "Documents", view: builtRail(.documents)),
                        .init(label: "History", view: builtRail(.history))
                    ]
                )
            ],
            width: 229
        )
    }

    @Test func `the sections of the sidebars as built, drawn for the owner`() throws {
        guard let folder = ProcessInfo.processInfo.environment["SUNSET_CATALOG"].map({ URL(fileURLWithPath: $0) })
        else { return }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        #expect(sectionsBuilt.write(to: folder.appending(path: "sections-built.png")))
    }
}
