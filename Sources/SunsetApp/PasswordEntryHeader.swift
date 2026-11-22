import SunsetCredentials
import SunsetShell
import SwiftUI

/// The top of an entry's page: its picture on a tinted tile, its title (a field while edited) and its kind; Edit, or
/// Cancel and Done, at its end.
struct PasswordEntryHeader: View {
    @Binding var entry: VaultEntry
    let editing: Bool
    let canSave: Bool
    let edit: () -> Void
    let cancel: () -> Void
    let done: () -> Void

    var body: some View {
        HStack(spacing: Design.Space.m) {
            Image(systemName: PasswordLook.symbol(entry))
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: Self.tile, height: Self.tile)
                .background(
                    Color.accentColor.gradient,
                    in: RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
                )
            VStack(alignment: .leading, spacing: Design.Space.hair) {
                if editing {
                    TextField("Title", text: $entry.title, prompt: Text(PasswordLook.prompt(entry)))
                        .textFieldStyle(.plain)
                        .labelsHidden()
                        .font(.title2.weight(.semibold))
                } else {
                    Text(PasswordLook.title(entry)).font(.title2.weight(.semibold)).lineLimit(1)
                }
                Text(PasswordLook.template(entry)?.name ?? "Entry").foregroundStyle(.secondary)
            }
            Spacer(minLength: Design.Space.m)
            if editing {
                Button("Cancel", action: cancel).keyboardShortcut(.cancelAction)
                Button("Done", action: done).keyboardShortcut(.defaultAction).disabled(!canSave)
            } else {
                Button("Edit", action: edit)
            }
        }
        .padding(.vertical, Design.Space.xs)
    }

    /// The picture's tile, as an app's icon in a list of settings.
    private static let tile = 44.0
    /// An app icon's corner at that size.
    private static let corner = 10.0
}
