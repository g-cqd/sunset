import SunsetWeb
import SwiftUI
import WebKit

/// History > Clear History… (web step e): a span and what goes with it, each its own choice (the owner: every variant left to the user).
struct ClearHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var span = ClearSpan.lastHour
    @State private var history = true
    @State private var websiteData = false
    @State private var siteZoom = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Clear History").font(.headline)
            Picker("Clear", selection: $span) {
                ForEach(ClearSpan.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .fixedSize()
            VStack(alignment: .leading, spacing: 6) {
                Toggle("History of pages visited", isOn: $history)
                Toggle("Website data: cookies, caches and what sites store", isOn: $websiteData)
                if websiteData {
                    Text("You will be signed out of the sites visited in this span.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 20)
                }
                Toggle("Zoom levels of sites", isOn: $siteZoom)
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Clear") {
                    WebClearing.clear(
                        since: span.start(),
                        history: history,
                        websiteData: websiteData,
                        siteZoom: siteZoom
                    )
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!history && !websiteData && !siteZoom)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}
