import AppKit
import SunsetConfig
import SunsetShell
import SunsetWeb
import SwiftUI

/// The controls of Settings that are built by hand (`SettingsControl.Custom`).
struct SettingsCustomRow: View {
    let custom: SettingsControl.Custom
    let option: SettingsOption
    let config: any SettingsStore

    var body: some View {
        switch custom {
            case .ansiPalette: AnsiPaletteRow(config: config)
            case .scrollback:
                NumberRow(
                    name: option.title,
                    value: Binding(
                        get: { Double(config.configuration.scrollbackLines) },
                        set: { value in config.update { $0.scrollbackLines = Int(value) } }
                    ),
                    range: 0 ... 10_000_000,
                    step: 1000,
                    unit: "lines",
                    fractionDigits: 0
                )
            case .blinkTimeout: blinkTimeout
            case .searchEngine:
                LabeledContent {
                    Picker(option.title, selection: config.binding(\.web.engine)) {
                        ForEach(PaneContentKinds.webSettings.engines, id: \.name) { engine in
                            Text("\(engine.name)  (\(engine.keyword))").tag(engine.name)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                } label: {
                    SettingsLabel(option.title)
                }
            case .startProfile: StartProfilePicker(title: option.title, config: config)
            case .engines: EngineList(engines: config.binding(\.web.engines))
            case .websites: WebsitesSettings(defaults: config.binding(\.web.permissions), profile: config.profileID)
            case .siteAgents: SiteAgentsSettings(agent: config.binding(\.web.agent))
            case .profiles: ProfilesSettings(note: option.note)
            case .proxyCheck: ProxyCheckRow(address: config.configuration.web.proxy, title: option.title)
            case .blockingLists: BlockingListsSettings()
            case .sites: SitesSettings(config: config)
            case .extensions: ExtensionsSettings()
            case .features: FeaturesSettings(features: config.binding(\.features))
            case .fileLocation: fileInfo
            case .storageSealed, .storageWebsiteData, .storageSetAside, .storageKey, .storageEnterCode, .storageExport:
                StorageRows(custom: custom)
            case .defaultBrowser: DefaultBrowserRow()
            case .updates: UpdatesCenter()
            case .quickLookMarkdown: QuickLookMarkdownRow()
            case .textOnlyZoom:
                if WebTextZoomProbe.isAvailable {
                    LabeledContent {
                        Toggle(option.title, isOn: config.binding(\.web.textOnlyZoom)).labelsHidden()
                    } label: {
                        SettingsLabel("Zoom makes only the text bigger")
                    }
                }
        }
    }

    /// The cursor blinks for ever, or stops after a number of seconds.
    @ViewBuilder private var blinkTimeout: some View {
        LabeledContent {
            Toggle(
                "Cursor blinks for ever",
                isOn: Binding(
                    get: { config.configuration.cursorBlinkTimeout == nil },
                    set: { forever in config.update { $0.cursorBlinkTimeout = forever ? nil : 15 } }
                )
            )
            .labelsHidden()
        } label: {
            SettingsLabel("Cursor blinks for ever")
        }
        NumberRow(
            name: option.title,
            value: config.binding(\.cursorBlinkTimeoutSeconds),
            range: 1 ... 3600,
            step: 1,
            unit: "s"
        )
        .disabled(config.configuration.cursorBlinkTimeout == nil)
    }

    private static let fileNote =
        "Saving here rewrites the file with every option; comments in a hand-written file are not kept (the previous file is "
        + "saved as `config.json.bak`)."

    private var fileInfo: some View {
        VStack(alignment: .leading, spacing: Design.Space.m) {
            LabeledContent {
                Text(AppConfiguration.shared.path).code().font(Design.Text.secondary).textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } label: {
                SettingsLabel(option.title)
            }
            HStack {
                Spacer()
                Button("Reveal in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: AppConfiguration.shared.path)])
                }
                .disabled(!AppConfiguration.shared.hasFile)
                Button("Open in editor") { NSWorkspace.shared.open(URL(fileURLWithPath: AppConfiguration.shared.path)) }
                    .disabled(!AppConfiguration.shared.hasFile)
            }
            if let error = AppConfiguration.shared.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
            }
            ForEach(Array(AppConfiguration.shared.issues.enumerated()), id: \.offset) { _, issue in
                Label("\(issue.path): \(issue.message)", systemImage: "exclamationmark.circle").foregroundStyle(.orange)
            }
            Text(RichText.attributed(Self.fileNote)).font(Design.Text.detail).foregroundStyle(.secondary)
        }
    }
}
