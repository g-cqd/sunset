import SunsetMetrics
import SwiftUI

/// A kept page away from where it was kept (the owner's notes n3 and n5): a small dot under its icon, centred on it, between
/// the icon and the row's bottom edge, in a Pinned tile and a Favorites row alike; a double click on the row takes it back.
struct AwayBadge: View {
    /// The dot's diameter.
    static let size = 4.0

    var body: some View {
        Circle()
            .fill(.secondary)
            .frame(width: Self.size, height: Self.size)
            .accessibilityLabel("Away from where it was kept")
            .transition(.opacity)
    }
}

extension View {
    /// The away dot under a row's icon (centred in the row's height), halfway between the icon's bottom and the row's:
    /// `iconCentre` points from the row's leading edge (nil: the row's middle, a tile's).
    func awayDot(_ shown: Bool, iconCentre: Double? = nil) -> some View {
        overlay {
            if shown {
                GeometryReader { proxy in
                    let height = proxy.size.height
                    AwayBadge()
                        .position(
                            x: iconCentre ?? proxy.size.width / 2,
                            y: (height / 2 + Design.Size.glyphFrame / 2 + height) / 2
                        )
                }
                .allowsHitTesting(false)
            }
        }
    }
}
