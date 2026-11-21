import SunsetImport
import SunsetPane
import SunsetShell
import SwiftUI
import UniformTypeIdentifiers

/// File ▸ Import from Another Browser… (roadmap 0111 G; the owner's note n75): a browser on this Mac and one of its
/// profiles, or an exported bookmarks file, into this Space or a new one. Extensions are offered by their store pages,
/// installed by the person (roadmap 0109); nothing is installed or overwritten silently.
struct ImportSheet: View {
    let tabs: TabsModel
    @Environment(\.dismiss) private var dismiss
    @State private var browsers: [Browser] = []
    @State private var browser: String?
    @State private var profiles: [BrowserProfile] = []
    @State private var profile: String?
    @State private var intoNewSpace = true
    @State private var choosingFile = false
    /// The source being read; set by Import, read by the task.
    @State private var running: ImportRun.Source?
    @State private var phase = Phase.choosing

    enum Phase: Equatable {
        case choosing
        case reading
        case needsAccess(String)
        case failed(String)
        case done(ImportOutcome)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.xl) {
            Text("Import from Another Browser").font(Design.Text.title)
            switch phase {
                case .done(let outcome): ImportResultView(outcome: outcome, tabs: tabs) { dismiss() }
                default: choosing
            }
        }
        .padding(Design.Space.xxl)
        .frame(width: Design.Width.sharePanel, alignment: .leading)
        .onAppear {
            browsers = ImportRun.browsers()
            browser = browsers.first?.name
        }
        .task(id: browser) { await loadProfiles() }
        .task(id: running) { await read() }
        .fileImporter(isPresented: $choosingFile, allowedContentTypes: [.html]) { result in
            if case .success(let url) = result { running = .file(url) }
        }
    }

    @ViewBuilder private var choosing: some View {
        if browsers.isEmpty {
            Text("No other browser was found on this Mac. An exported bookmarks file can be imported.")
                .foregroundStyle(.secondary)
        } else {
            Picker("Browser", selection: $browser) {
                ForEach(browsers) { Text($0.name).tag(Optional($0.name)) }
            }
            if profiles.count > 1 {
                Picker("Profile", selection: $profile) {
                    ForEach(profiles, id: \.folder) { Text($0.name).tag(Optional($0.folder)) }
                }
            }
            Picker("Into", selection: $intoNewSpace) {
                Text("A new Space").tag(true)
                Text("This Space\u{2019}s Favorites").tag(false)
            }
            .pickerStyle(.radioGroup)
        }
        ImportPhaseNote(phase: phase)
        HStack {
            Button("Exported Bookmarks File\u{2026}") { choosingFile = true }
            Spacer()
            Button("Cancel", role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction)
            Button("Import") { start() }
                .keyboardShortcut(.defaultAction)
                .disabled(selected == nil || phase == .reading)
        }
    }

    private var selected: ImportRun.Source? {
        guard let found = browsers.first(where: { $0.name == browser }),
            let chosen = profiles.first(where: { $0.folder == profile }) ?? profiles.first
        else { return nil }
        return .profile(found, chosen)
    }

    private func start() {
        guard let selected else { return }
        running = selected
    }

    private func loadProfiles() async {
        profiles = []
        profile = nil
        guard let found = browsers.first(where: { $0.name == browser }) else { return }
        do {
            profiles = try await ImportRun.profiles(of: found)
            profile = profiles.first?.folder
            phase = .choosing
        } catch {
            phase = Self.phase(for: error)
        }
    }

    private func read() async {
        guard let source = running else { return }
        phase = .reading
        do {
            let read = try await ImportRun.read(source)
            phase = .done(place(read, from: source))
        } catch {
            phase = Self.phase(for: error)
        }
        running = nil
    }

    /// The bookmarks placed, in one folder: in a new Space, or this one's Favorites.
    private func place(_ read: ImportedProfile, from source: ImportRun.Source) -> ImportOutcome {
        let names = ImportRun.names(source)
        let (favorites, report) = FavoritesImport.favorites(from: read.bookmarks)
        var space = tabs.space.space.shownName
        if !favorites.isEmpty, let spaces = tabs.spaces {
            let target = intoNewSpace ? nil : tabs.space
            let went = spaces.importFavorites(favorites, folder: names.folder, into: target, newSpace: names.space)
            space = went.space.shownName
        }
        return ImportOutcome(
            report: report,
            folder: names.folder,
            space: space,
            extensions: read.extensions,
            containers: read.containers
        )
    }

    static func phase(for error: any Error) -> Phase {
        switch error as? BrowserImport.Failure {
            case .needsAccess(let path): .needsAccess(path)
            case .unreadable(let path): .failed("\((path as NSString).lastPathComponent) could not be read.")
            case nil: .failed(error.localizedDescription)
        }
    }
}
