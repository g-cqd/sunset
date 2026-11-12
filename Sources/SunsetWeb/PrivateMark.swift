import SwiftUI

/// "Private" at the start of a private page's address field (web step h); a click tells what is kept and, in a private window, offers its selector.
struct PrivateMark: View {
    @Environment(\.privateWindowSharing) private var sharing
    @State private var open = false

    var body: some View {
        Button {
            open.toggle()
        } label: {
            Text("Private")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.white.opacity(0.18)))
        }
        .buttonStyle(.plain)
        .help("A private page")
        .popover(isPresented: $open, arrowEdge: .bottom) { details }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Private Page").font(.headline)
            Text(
                "Its cookies and storage stay in memory and go when it closes. No history, no zoom, no site answers and no download entry are kept; it is not restored after Sunset quits."
            )
            .font(.callout)
            .fixedSize(horizontal: false, vertical: true)
            if let sharing {
                Divider()
                Toggle("Private pages of this window share their data", isOn: sharing)
                Text("Applies to the pages opened after the change.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(width: 300, alignment: .leading)
    }
}
