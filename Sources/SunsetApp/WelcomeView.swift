import SunsetConfig
import SunsetShell
import SunsetShellModel
import SwiftUI

/// The welcome (roadmap 0111 H; docs/research/welcome-design.md): the sky the whole window, the sun low; one question a
/// page, its text left-aligned in the darker sky above, answered with the system's own controls; Back, Skip Setup and one
/// primary button below. Return goes on, ← and → move, Esc leaves. Answers are written at once and stay in Settings.
struct WelcomeView: View {
    let store: AppConfiguration
    let clock: WelcomeOpeningClock
    let close: () -> Void
    @State private var index = 0

    private var steps: [WelcomeStep] {
        WelcomeStep.steps(for: store.configuration.features)
    }

    private var step: WelcomeStep {
        steps[min(index, steps.count - 1)]
    }

    var body: some View {
        WelcomeOpeningFocus(clock: clock) { content }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            WelcomePage(step: step, position: index + 1, count: steps.count, store: store, close: close)
                .id(step)
                .transition(.opacity)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
            buttons
        }
        .padding(Design.Welcome.margin)
        .background {
            ZStack {
                SunsetSkyView { _, size in SunsetSkyFrame.window(size) }
                // Dimmed where text and controls sit: the upper sky, and the band of the buttons under the sun.
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(Design.Welcome.dimming), location: 0),
                        .init(color: .clear, location: Design.Welcome.dimmingReach),
                        .init(color: .clear, location: Design.Welcome.buttonsDimmingStart),
                        .init(color: .black.opacity(Design.Welcome.dimming), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .environment(\.colorScheme, .dark)
        .frame(width: Design.Welcome.size.width, height: Design.Welcome.size.height)
        .ignoresSafeArea()
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.leftArrow) { go(-1) }
        .onKeyPress(.rightArrow) { go(1) }
    }

    private var buttons: some View {
        HStack(spacing: Design.Welcome.row) {
            if index > 0 {
                Button("Back") { _ = go(-1) }.buttonStyle(.glass)
            }
            Spacer()
            if step != .done {
                Button("Skip Setup", action: close).buttonStyle(.glass).keyboardShortcut(.cancelAction)
            }
            Button(step == .done ? "Start Using Sunset" : "Continue") {
                if step == .done { close() } else { _ = go(1) }
            }
            .buttonStyle(.glassProminent)
            .tint(Design.Welcome.accent)
            .keyboardShortcut(.defaultAction)
        }
        .controlSize(.large)
        // The buttons sit on the bright band under the sun: the light appearance there, dark labels on light glass (seen:
        // light labels on the dark appearance's glass, washed out).
        .environment(\.colorScheme, .light)
    }

    private func go(_ by: Int) -> KeyPress.Result {
        let next = min(max(index + by, 0), steps.count - 1)
        guard next != index else { return .ignored }
        withAnimation(Design.Welcome.change) { index = next }
        return .handled
    }
}
