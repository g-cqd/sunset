import AppKit
import SunsetConfig
import SunsetHelp
import SunsetRuntime
import SunsetShell
import SwiftUI

/// Settings › Appearance › App icon (n142): previews of each icon (Auto showing the current sky of the day with a small
/// clock badge, plus Dawn, Sunset, Twilight and Dusk) instead of a text dropdown. The proposed skies (`Icon.proposed`) show
/// while Option is held, or while one of them is the one chosen.
struct AppIconPickerRow: View {
    let title: String
    let help: HelpTopic?
    let config: any SettingsStore
    @Environment(\.runtime) private var runtime
    @State private var option = false

    private static let choices: [(icon: Configuration.Appearance.Icon, label: String)] = [
        (.auto, "Auto"), (.dawn, "Dawn"), (.sunset, "Sunset"), (.twilight, "Twilight"), (.dusk, "Dusk")
    ]

    private var proposed: [Configuration.Appearance.Icon] {
        let chosen = config.configuration.appearance.icon
        return option || Configuration.Appearance.Icon.proposed.contains(chosen)
            ? Configuration.Appearance.Icon.proposed : []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Space.m) {
            SettingsLabel(title, help: help)
            HStack(spacing: Design.Space.l) {
                ForEach(Self.choices, id: \.icon) { item in
                    tile(for: item.icon, label: item.label)
                }
            }
            if !proposed.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: Design.Space.l) {
                        ForEach(proposed, id: \.self) { icon in tile(for: icon, label: icon.title) }
                    }
                }
                .scrollIndicators(.hidden)
                .transition(.opacity)
            }
        }
        .animation(Design.Welcome.change, value: proposed)
        .onModifierKeysChanged(mask: .option, initial: true) { _, keys in option = keys.contains(.option) }
    }

    private func tile(for icon: Configuration.Appearance.Icon, label: String) -> some View {
        let selected = config.configuration.appearance.icon == icon
        let shown = icon.resolved(at: runtime.now())
        return Button {
            config.update { $0.appearance.icon = icon }
        } label: {
            VStack(spacing: Design.Space.xs) {
                preview(of: shown, isAuto: icon == .auto, selected: selected)
                Text(label)
                    .font(Design.Text.detail)
                    .fontWeight(selected ? .semibold : .regular)
                    .foregroundStyle(selected ? .primary : .secondary)
            }
            .padding(Design.Space.s)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func preview(of sky: Configuration.Appearance.Icon, isAuto: Bool, selected: Bool) -> some View {
        let image = NSImage(named: sky.assetName) ?? NSApp?.applicationIconImage ?? NSImage()
        return ZStack(alignment: .bottomTrailing) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: Design.Size.alertIcon, height: Design.Size.alertIcon)
            if isAuto { autoBadge }
        }
        .padding(Design.Space.xs)
        .background(
            selected ? Color.accentColor.opacity(Design.Fill.tabSelected) : .clear,
            in: .rect(cornerRadius: Design.Size.extensionPopupRadius, style: .continuous)
        )
        .overlay {
            if selected {
                RoundedRectangle(cornerRadius: Design.Size.extensionPopupRadius, style: .continuous)
                    .strokeBorder(Color.accentColor, lineWidth: Design.Space.hair)
            }
        }
    }
    private var autoBadge: some View {
        Circle()
            .fill(.black.opacity(Design.Fill.veil))
            .overlay {
                Image(systemName: "clock.fill")
                    .font(.system(size: Design.Symbol.badge, weight: Design.Symbol.weight))
                    .foregroundStyle(.white)
            }
            .frame(width: Design.Size.glyphFrame, height: Design.Size.glyphFrame)
    }
}
