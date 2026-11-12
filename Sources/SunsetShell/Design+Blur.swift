package import AemiSDR

extension Design {
    /// The blurs under the bars and behind the command bar (Sunset research/blur, variant A; AemiSDR roadmap 0020).
    package enum Blur {
        /// Under a bar: full over the bar, falling to none over a bar's height beyond it.
        package static let barRadius = 8.0
        /// How far the blur under a bar falls below it: two bars' heights (owner, 2026-11-13).
        package static let barFall = 2 * Size.bar
        /// The fall starts half way down the bar, not after it (owner, 2026-11-13): full blur from the window's edge to the bar's
        /// middle, then falling through the bar's lower half and its margin to `barFall` below it.
        package static let barSolid = Space.m + Size.bar / 2
        package static let barFade = (barSolid + Size.bar / 2 + Space.m + barFall) * barKeep - barSolid
        /// The share of the full height (to two bars below the bar) the blur keeps (owner, 2026-11-13: a third less of the 130 pt it had).
        package static let barKeep = 0.67
        /// How far the sidebar's bands reach past its sides, so that no side of theirs shows: under the panes on one side (they draw
        /// above the sidebar), past the window's edge on the other (owner, 2026-11-13).
        package static let listBleed = Space.xxl
        /// At the ends of the sidebar's list, under the pin and the + bar.
        package static let listRadius = 12.0
        /// The part of a list end that is fully blurred (the rest falls to none)...
        package static let listSolidShare = 0.25
        /// ...and how far the fall reaches past it, over the rows at rest: a long fall leaves no line where a row comes back, and
        /// the cubic ramp's tail there is under half a point of radius.
        package static let listOverhang = Space.m
        /// Behind the command bar: the whole window out of focus, still readable as shapes, barely darker (owner, 2026-11-13:
        /// "soft focus" of research/blur command-variants).
        package static let backdropRadius = 3.0
        package static let backdropDarkening = -0.05

        /// A small floating panel (the find bar): an even blur, livelier colour.
        package static var panel: BlurRecipe {
            var recipe = BlurRecipe.uniform(radius: panelRadius)
            recipe.saturation = panelSaturation
            return recipe
        }

        /// A panel's halo over a layer of `width` × `height` (`BlurHalo`).
        package static func halo(_ halo: BlurHalo, width: Double, height: Double) -> BlurRecipe {
            var recipe = BlurRecipe.variable(
                radius: haloRadius,
                mask: .corner(halo.corner, width: width, height: height, fade: halo.inset + halo.reach)
            )
            recipe.saturation = panelSaturation
            return recipe
        }

        /// Around a floating panel (the find bar): a low radius, falling to none over a long fade (owner, 2026-11-13).
        package static let haloRadius = barRadius
        /// The fall starts `haloInset` inside the panel's edge (under its dark fill) and ends `haloReach` outside it (owner,
        /// 2026-11-13: start earlier, end shorter; A of research/blur halo variants).
        package static let haloInset = Space.l
        package static let haloReach = Space.xl
        package static let panelRadius = 20.0
        package static let panelSaturation = 1.8

        package static func under(_ edge: BlurMask.Edge, solid: Double, fade: Double, radius: Double = barRadius)
            -> BlurRecipe
        {
            .variable(radius: radius, mask: .edge(edge, solid: solid, fade: fade))
        }

        package static var commandBackdrop: BlurRecipe {
            var recipe = BlurRecipe.uniform(radius: backdropRadius)
            recipe.brightness = backdropDarkening
            return recipe
        }
    }
}
