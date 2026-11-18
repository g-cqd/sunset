import SunsetPane
import SunsetShell
import SunsetWeb
import SwiftUI

/// Settings > Web > Profiles (R4; ADR-0053): the profiles, each named in place; a new one; and a profile removed, after
/// a question: its Spaces become the first profile's, what it kept (pinned, favourites) is removed, and its website data is erased.
struct ProfilesSettings: View {
    /// The page's heading over the first section, when it is the page's first block.
    var heading: String?
    var title = "Your profiles"
    var note: String?
    private let spaces = AppSpaces.all
    @State private var removing: ProfileModel?

    var body: some View {
        Group {
            // New Profile in the list's heading, on its own: nothing of one profile is next to it (the owner's note n39).
            Section {
                EmptyView()
            } header: {
                VStack(alignment: .leading, spacing: Design.Space.m) {
                    if let heading { Text(heading).font(Design.Text.heading).foregroundStyle(.primary) }
                    HStack {
                        Text(title)
                        Spacer()
                        Button("New Profile", systemImage: "plus") { spaces.profiles.add() }
                            .buttonStyle(.borderless)
                    }
                }
            } footer: {
                if let note { Text(RichText.attributed(note)).font(Design.Text.detail).foregroundStyle(.secondary) }
            }
            // Each profile a section of its own: what is under it is its (note n38).
            ForEach(spaces.profiles.profiles, id: \.profile.id) { profile in
                Section {
                    LabeledContent {
                        TextField(
                            "Profile name",
                            text: Binding(
                                get: { profile.profile.name },
                                set: { spaces.profiles.rename(profile, to: $0) }
                            ),
                            prompt: Text("Name")
                        )
                        .labelsHidden()
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: Design.Size.settingsField)
                    } label: {
                        SettingsLabel("Name")
                    }
                    LabeledContent {
                        Text(Self.sentence(spaces: spaces.spaces(of: profile).count)).foregroundStyle(.secondary)
                    } label: {
                        SettingsLabel("Spaces")
                    }
                    if !profile.profile.isFirst {
                        LabeledContent {
                            Button("Remove Profile\u{2026}", role: .destructive) { removing = profile }
                        } label: {
                            EmptyView()
                        }
                    }
                } header: {
                    Text(profile.profile.name.isEmpty ? "Profile" : profile.profile.name)
                }
            }
        }
        .confirmationDialog(
            "Remove the profile \u{201C}\(removing?.profile.name ?? "")\u{201D}?",
            isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } }),
            titleVisibility: .visible
        ) {
            Button("Remove and Erase Its Website Data", role: .destructive) { remove() }
            Button("Cancel", role: .cancel) { removing = nil }
        } message: {
            Text(
                "Its Spaces become \(spaces.profiles.first.profile.name)\u{2019}s and their pages load again. What is "
                    + "pinned or kept in its Favorites is removed. Its cookies, logins and storage are erased."
            )
        }
    }

    /// Its Spaces' pages are made again in the first profile, then nothing holds its data and it is erased.
    private func remove() {
        guard let profile = removing else { return }
        removing = nil
        let its = spaces.spaces(of: profile)
        guard let id = spaces.remove(profile: profile) else { return }
        for space in its { space.restart(kind: WebContent.kind, by: space.currentViewer) }
        Task { await ProfileData.erase(id) }
    }

    static func sentence(spaces count: Int) -> String {
        switch count {
            case 0: "no Space"
            case 1: "1 Space"
            default: "\(count) Spaces"
        }
    }
}
