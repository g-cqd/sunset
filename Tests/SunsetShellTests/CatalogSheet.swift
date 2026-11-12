import AppKit
import SwiftUI

/// A page of the design catalog: a title, then labelled examples in columns, drawn off-screen into a PNG (no window).
struct CatalogSheet {
    struct Example {
        let label: String
        let view: AnyView
    }

    struct Column {
        let title: String
        let examples: [Example]
    }

    let title: String
    let note: String
    let columns: [Column]
    var background = Color(white: 0.12)
    var width = 240.0

    @MainActor var view: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.title3.weight(.semibold))
            Text(note).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: Double(columns.count) * (width + 150), alignment: .leading)
            HStack(alignment: .top, spacing: 28) {
                ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(column.title).font(.headline)
                        ForEach(Array(column.examples.enumerated()), id: \.offset) { _, example in
                            HStack(alignment: .center, spacing: 10) {
                                Text(example.label).font(.caption).foregroundStyle(.secondary)
                                    .frame(width: 130, alignment: .trailing)
                                example.view.frame(width: width, alignment: .leading)
                            }
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(background)
        .environment(\.colorScheme, .dark)
    }

    /// Writes the sheet at 2x; returns whether it was written.
    @MainActor @discardableResult func write(to url: URL) -> Bool {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.cgImage else { return false }
        let rep = NSBitmapImageRep(cgImage: image)
        guard let data = rep.representation(using: .png, properties: [:]) else { return false }
        return (try? data.write(to: url)) != nil
    }
}
