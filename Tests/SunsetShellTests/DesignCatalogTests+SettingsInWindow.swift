import Foundation
import SwiftUI
import Testing

@testable import SunsetShell
@testable import SunsetShellModel

/// Mock-ups of the settings shown in a window (roadmap 0032, the owner on 2026-11-15): the sidebar lists the sections and their
/// topics, the pane area shows the settings. Drawn with plain shapes for the owner to choose from; nothing is built.
extension DesignCatalogTests {
    static let settingSections: [(String, String)] = [
        ("textformat", "Font"), ("paintpalette", "Colors"), ("sparkles", "Appearance"), ("macwindow", "Window"),
        ("sidebar.left", "Sidebar"), ("globe", "Web"), ("keyboard", "Keyboard")
    ]
    static let settingTopics = ["General", "Privacy", "Downloads", "Websites"]
    static let settingRail: [(String, String)] = [("rectangle.stack", "Tabs")] + librarySections

    /// A setting: its name, then a value or a switch.
    func settingRow(_ name: String, value: String? = nil, isOn: Bool = true) -> some View {
        HStack(spacing: 6) {
            Text(name).font(.system(size: 12)).lineLimit(1)
            Spacer(minLength: 4)
            if let value {
                Text(value).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 8)).foregroundStyle(.tertiary)
            } else {
                Capsule().fill(isOn ? Color.accentColor : Color.primary.opacity(0.2)).frame(width: 26, height: 15)
                    .overlay(alignment: isOn ? .trailing : .leading) {
                        Circle().fill(.white).frame(width: 12, height: 12).padding(1.5)
                    }
            }
        }
        .padding(.horizontal, 10).frame(height: 28)
    }

    func settingGroup(_ heading: String, @ViewBuilder _ rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(heading).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).padding(.leading, 4)
            VStack(spacing: 0) { rows() }
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(.primary.opacity(0.06)))
        }
    }

    /// The settings of one section, its topics as headings.
    func settingForm(found: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(found ? "Search: \u{201C}private\u{201D}" : "Web").font(.system(size: 15, weight: .semibold))
            settingGroup(found ? "Web \u{203A} Privacy" : "General") {
                if found {
                    settingRow("Private windows keep nothing")
                } else {
                    settingRow("Home page", value: "Start page")
                    settingRow("Search with", value: "DuckDuckGo")
                }
            }
            settingGroup(found ? "Window" : "Privacy") {
                if found {
                    settingRow("Private windows are tinted", isOn: false)
                } else {
                    settingRow("Block trackers")
                    settingRow("Private windows keep nothing")
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(white: 0.14))
    }

    /// The sections, the topics of the one shown under it.
    @ViewBuilder
    func settingList(selected: Int = 5, topics: Bool = true, compact: Bool = false) -> some View {
        ForEach(Array(Self.settingSections.enumerated()), id: \.offset) { index, section in
            HStack(spacing: 6) {
                Image(systemName: section.0).font(.system(size: 11)).frame(width: 16)
                if !compact { Text(section.1).font(.system(size: 12)).lineLimit(1) }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 7).frame(height: 24)
            .background(footFill(index == selected && !topics))
            if index == selected, topics, !compact {
                ForEach(Array(Self.settingTopics.enumerated()), id: \.offset) { topic, name in
                    Text(name).font(.system(size: 11)).foregroundStyle(topic == 0 ? .primary : .secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 29).frame(height: 20).background(footFill(topic == 0))
                }
            }
        }
    }

    /// A terminal, for a pane beside the settings.
    var settingTerminal: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("~/sunset \u{276F} swift build").foregroundStyle(.primary)
            Text("Compiling SunsetShell").foregroundStyle(.secondary)
            Text("Build complete! (4.2s)").foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .font(.system(size: 11, design: .monospaced))
        .padding(10).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).background(.black)
    }

    /// A window: a sidebar and the pane area.
    func settingWindow(sidebar: Double = 200, @ViewBuilder side: () -> some View, @ViewBuilder area: () -> some View)
        -> AnyView
    {
        AnyView(
            HStack(spacing: 0) {
                VStack(spacing: 3) {
                    side()
                    Spacer(minLength: 0)
                }
                .padding(5).frame(width: sidebar).background(Color(white: 0.09))
                HStack(spacing: 1) { area() }
            }
            .frame(width: 600, height: 356)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        )
    }

    /// W1: a gear at the foot of the Library's rail; the sidebar lists the sections; the settings are a tab.
    func settingInLibrary(split: Bool) -> AnyView {
        settingWindow(sidebar: 226) {
            HStack(alignment: .top, spacing: 5) {
                VStack(spacing: 4) {
                    ForEach(Array(Self.settingRail.enumerated()), id: \.offset) { _, section in
                        libraryTab(section, shown: false, look: .rail)
                    }
                    Spacer(minLength: 0)
                    libraryTab(("gearshape", "Settings"), shown: true, look: .rail)
                }
                .frame(width: 30)
                VStack(spacing: 3) {
                    sectionField("Search Settings")
                    settingList()
                }
            }
        } area: {
            settingForm()
            if split { settingTerminal }
        }
    }

    /// W2: the settings take the window; a way back at the top of the sidebar.
    func settingWholeWindow(found: Bool) -> AnyView {
        settingWindow {
            HStack(spacing: 5) {
                Image(systemName: "chevron.left").font(.system(size: 11, weight: .semibold))
                Text("Settings").font(.system(size: 13, weight: .semibold))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 7).frame(height: 26)
            sectionField(found ? "private" : "Search Settings")
            settingList(topics: !found)
        } area: {
            settingForm(found: found)
        }
    }

    /// W3: the settings are a tab that carries its own list; the sidebar stays the tabs'.
    func settingOwnList(split: Bool) -> AnyView {
        settingWindow {
            documentFavorites
            documentLine
            documentRow("fish", "terminal", DocumentRowLook(fill: 0.06))
            documentRow("Settings", "gearshape", DocumentRowLook(fill: 0.14, stroke: true, trail: .close))
        } area: {
            HStack(spacing: 0) {
                VStack(spacing: 3) {
                    settingList(topics: false, compact: split)
                    Spacer(minLength: 0)
                }
                .padding(5).frame(width: split ? 38 : 112).background(Color(white: 0.11))
                settingForm()
            }
            if split { settingTerminal }
        }
    }

    var settingsInWindowSheet: CatalogSheet {
        CatalogSheet(
            title: "Settings in the window (mock-up, 0032)",
            note:
                "W1: a gear at the foot of the Library's rail; the sidebar lists the sections with the topics of the one shown, "
                + "and the settings are a tab like any other, so they can sit beside a terminal and one sees a change as it is "
                + "made. W2: the settings take the whole window; a chevron at the top of the sidebar goes back to the tabs. "
                + "W3: the settings are a tab that carries its own list, the sidebar stays the tabs'.",
            columns: [
                .init(
                    title: "W1 a section of the Library, the settings a tab",
                    examples: [
                        .init(label: "alone", view: settingInLibrary(split: false)),
                        .init(label: "beside a terminal", view: settingInLibrary(split: true))
                    ]
                ),
                .init(
                    title: "W2 the settings take the window",
                    examples: [
                        .init(label: "a section", view: settingWholeWindow(found: false)),
                        .init(label: "searching", view: settingWholeWindow(found: true))
                    ]
                ),
                .init(
                    title: "W3 a tab with its own list",
                    examples: [
                        .init(label: "alone", view: settingOwnList(split: false)),
                        .init(label: "beside a terminal", view: settingOwnList(split: true))
                    ]
                )
            ],
            width: 600
        )
    }

    @Test func `the settings in the window, drawn for the owner`() throws {
        guard let folder = ProcessInfo.processInfo.environment["SUNSET_CATALOG"].map({ URL(fileURLWithPath: $0) })
        else { return }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        #expect(settingsInWindowSheet.write(to: folder.appending(path: "settings-in-window.png")))
    }
}
