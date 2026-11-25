import SunsetShell
import SwiftUI

/// Progress indicator shared by Settings (`UpdatesCenter`, `UpdateComponentRow`) and the update window (`UpdateNotes`):
/// spins indeterminately during preparing/unpacking/verifying (or before bytes arrive), and renders a linear bar with
/// percentage while bytes stream in.
struct UpdateProgressView: View {
    let progress: UpdateTransfer.Progress?
    var showsLabel: Bool = true

    var body: some View {
        HStack(spacing: Design.Space.s) {
            if let fraction = progress?.fraction, fraction > 0 {
                ProgressView(value: fraction)
                    .progressViewStyle(.linear)
                    .controlSize(.small)
                    .frame(width: 96)
                if showsLabel {
                    Text(verbatim: "\(Int((fraction * 100).rounded()))%")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            } else {
                ProgressView().controlSize(.small)
                if showsLabel {
                    Text(label).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var label: String {
        switch progress?.stage ?? .preparing {
            case .preparing: "Preparing\u{2026}"
            case .downloading: "Downloading\u{2026}"
            case .installing: "Preparing update\u{2026}"
            case .verifying: "Verifying\u{2026}"
        }
    }
}
