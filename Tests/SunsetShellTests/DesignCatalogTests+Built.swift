import Foundation
import SunsetMetrics
import SunsetPane
import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// The sections of the sidebars as built (0030 step ST-5): a document's tab among the tabs, the switch at the foot of
/// the opposite panel, the Library's rail. The real views, drawn off screen.
extension DesignCatalogTests {
    /// A window's tabs: a terminal, and a document's tab (edited when `edited`), shown or not.
    private func documentTabs(edited: Bool, shown: Bool) -> TabsHarness {
        let harness = TabsHarness()
        harness.tabs.newTab()
        harness.made.last?.title = "fish"
        harness.made.last?.glyphValue = .symbol("terminal")
        harness.tabs.show(document: UUID())
        harness.made.last?.title = "Harbour notes"
        harness.made.last?.glyphValue = .symbol("doc.text")
        harness.made.last?.isEdited = edited
        harness.tabs.newTab()
        harness.made.last?.title = "Example Domain"
        harness.made.last?.glyphValue = .symbol("globe")
        if shown { harness.tabs.select(index: 1) }
        return harness
    }

    private func builtSidebar(_ harness: TabsHarness) -> AnyView {
        let settings = ShellSettings()
        return AnyView(
            VStack(spacing: settings.layout.tabSpacing) {
                ForEach(harness.tabs.workspace.items) { item in
                    SidebarRow(
                        model: harness.tabs.contents[item.focused],
                        selected: harness.tabs.isSelected(item.id),
                        parts: TabParts(icon: true, title: true, directory: false, progress: false),
                        layout: settings.layout
                    ) {}
                }
            }
            .padding(4).background(Color(white: 0.09))
        )
    }

    private var builtButtons: SidebarButtons {
        SidebarButtons(layout: LayoutMetrics(), margin: 4, panelRadius: nil)
    }

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
                "A document is a tab like any other (the edited mark at its row's end). The switch at the foot of the panel "
                + "opposite the tabs. The Library's rail: Tabs, Documents, History, Downloads; the gear of the settings and "
                + "the way back at its foot.",
            columns: [
                .init(
                    title: "A document is a tab among the tabs",
                    examples: [
                        .init(label: "not shown", view: builtSidebar(documentTabs(edited: false, shown: false))),
                        .init(label: "shown, edited", view: builtSidebar(documentTabs(edited: true, shown: true)))
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

    @Test func `the sections of the sidebars as built, drawn`() throws {
        guard let folder = ProcessInfo.processInfo.environment["SUNSET_CATALOG"].map({ URL(fileURLWithPath: $0) })
        else { return }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        #expect(sectionsBuilt.write(to: folder.appending(path: "sections-built.png")))
    }
}
