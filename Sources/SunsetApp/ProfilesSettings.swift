import SunsetPane
import SunsetShell
import SunsetWeb
import SwiftUI

/// Settings > Web > Profiles (R4; ADR-0053): the profiles, each named in place; a new one; and a profile removed, after
/// a question: its Spaces become the first profile's, what it kept (pinned, favourites) is removed, and its website data is erased.
struct ProfilesSettings: View {
    private let spaces = AppSpaces.all
    @State private var removing: ProfileModel?

    var body: some View {
        Group {
            // Each profile's name in a field on the leading edge (its label), what it holds and Remove on the trailing one.
            ForEach(spaces.profiles.profiles, id: \.profile.id) { profile in
                LabeledContent {
                    HStack(spacing: Design.Space.m) {
                        Text(Self.sentence(spaces: spaces.spaces(of: profile).count)).foregroundStyle(.secondary)
                        if !profile.profile.isFirst {
                            Button("Remove\u{2026}") { removing = profile }
                        }
                    }
                } label: {
                    TextField(
                        "Profile name",
                        text: Binding(get: { profile.profile.name }, set: { spaces.profiles.rename(profile, to: $0) }),
                        prompt: Text("Name")
                    )
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: Design.Size.settingsField)
                }
            }
            LabeledContent {
                Button("New Profile") { spaces.profiles.add() }
            } label: {
                EmptyView()
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
