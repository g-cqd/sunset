package import AemiSDR

extension Design {
    /// The blurs under the bars and behind the command bar (Sunset research/blur, variant A; AemiSDR roadmap 0020).
    package enum Blur {
        /// Under a bar: full over the bar, falling to none over a bar's height beyond it.
        package static let barRadius = 24.0
        /// At the ends of the sidebar's list, under the pin and the + bar.
        package static let listRadius = 12.0
        /// The part of a list end that is fully blurred (the rest falls to none)...
        package static let listSolidShare = 0.25
        /// ...and how far the fall reaches past it, over the rows at rest: a long fall leaves no line where a row comes back, and
        /// the cubic ramp's tail there is under half a point of radius.
        package static let listOverhang = Space.m
        /// Behind the command bar: the whole window, softly, a little darker.
        package static let backdropRadius = 8.0
        package static let backdropDarkening = -0.15

        /// A small floating panel (the find bar): an even blur, livelier colour.
        package static var panel: BlurRecipe {
            var recipe = BlurRecipe.uniform(radius: panelRadius)
            recipe.saturation = panelSaturation
            return recipe
        }

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
