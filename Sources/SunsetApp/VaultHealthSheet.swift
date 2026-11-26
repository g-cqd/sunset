import SunsetAppCore
import SunsetCredentials
import SunsetShell
import SwiftUI

/// Offline Password Health summary sheet (roadmap 0092 F): runs `VaultHealthReport.analyze` purely locally over the
/// unlocked vault entries and lists weak or reused passwords with one-click navigation to fix each entry.
struct VaultHealthSheet: View {
    let model: PasswordsModel
    let openEntry: (UUID) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let report = VaultHealthReport.analyze(model.entries)
        let byID = Dictionary(uniqueKeysWithValues: model.entries.map { ($0.id, $0) })
        VStack(alignment: .leading, spacing: Design.Space.m) {
            HStack {
                Label("Password Health", systemImage: "checkmark.shield")
                    .font(Design.Text.title)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            Text(summaryText(report))
                .font(Design.Text.detail)
                .foregroundStyle(.secondary)
            if report.weak.isEmpty && report.reused.isEmpty {
                ContentUnavailableView(
                    "All Passwords Look Strong",
                    systemImage: "checkmark.seal",
                    description: Text("No weak or reused passwords were found across \(report.totalPasswords) checked.")
                )
                .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                let groups: [(title: String, badge: String, findings: [VaultHealthReport.Finding])] = [
                    ("Reused Passwords", "Reused", report.reused),
                    ("Weak Passwords", "Weak", report.weak)
                ]
                List {
                    ForEach(groups, id: \.badge) { group in
                        if !group.findings.isEmpty {
                            Section("\(group.title) (\(group.findings.count))") {
                                ForEach(uniqueEntries(group.findings, in: byID)) { entry in
                                    findingRow(entry, badge: group.badge)
                                }
                            }
                        }
                    }
                }
                .listStyle(.inset)
                .frame(minHeight: 220, maxHeight: 360)
            }
        }
        .padding(Design.Space.l)
        .frame(width: 440)
    }

    private func summaryText(_ report: VaultHealthReport) -> String {
        "Checked \(report.totalPasswords) password(s) offline on this Mac — nothing leaves your vault."
    }

    private func uniqueEntries(_ findings: [VaultHealthReport.Finding], in byID: [UUID: VaultEntry]) -> [VaultEntry] {
        var seen: Set<UUID> = []
        return findings.compactMap { finding in
            guard seen.insert(finding.entryID).inserted else { return nil }
            return byID[finding.entryID]
        }
    }

    private func findingRow(_ entry: VaultEntry, badge: String) -> some View {
        Button {
            openEntry(entry.id)
            dismiss()
        } label: {
            HStack {
                Image(systemName: PasswordLook.symbol(entry))
                    .foregroundStyle(.secondary)
                Text(PasswordLook.title(entry))
                    .lineLimit(1)
                Spacer()
                Text(badge)
                    .font(Design.Text.detail)
                    .foregroundStyle(.orange)
            }
        }
        .buttonStyle(.plain)
    }
}
