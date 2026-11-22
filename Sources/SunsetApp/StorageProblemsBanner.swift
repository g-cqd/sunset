import AppKit
import SunsetShell
import SunsetStorage
import SwiftUI

/// Says, at the top of the window, what Sunset keeps that did not read (never dropped silently: a banner once, and the
/// list stays in Settings). One line per file: what it was, where it was moved aside, Show in Finder, and a button that
/// puts the banner away.
struct StorageProblemsBanner: ViewModifier {
    var problems = StorageProblems.shared
    @Environment(\.surfaceStyle) private var surface

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if !problems.items.isEmpty {
                VStack(alignment: .leading, spacing: Design.Space.s) {
                    ForEach(problems.items) { problem in row(problem) }
                }
                .padding(Design.Space.l)
                .frame(maxWidth: Design.Width.commandBar, alignment: .leading)
                .surface(surface.panelShape, shadow: .popover)
                .padding(Design.Space.l)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(surface.layout.smooth, value: problems.items)
    }

    private func row(_ problem: StorageProblem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Design.Space.m) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
            Text(verbatim: problem.sentence).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Design.Space.m)
            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: problem.movedTo ?? problem.path)])
            }
            Button {
                problems.dismiss(problem)
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .help("Dismiss")
        }
        .font(Design.Text.small)
    }
}
