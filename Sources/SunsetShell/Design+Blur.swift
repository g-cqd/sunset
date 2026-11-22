package import AemiSDR

extension Design {
    /// The blurs under the bars and behind the command bar (variant A of the blurs studied, `docs/research`).
    package enum Blur {
        /// Under a bar: full over the bar, falling to none over a bar's height beyond it.
        package static let barRadius = 8.0
        /// Under one group of a bar's controls (`View.barGroup`): full to its bottom edge, then falling `groupFall` below it and
        /// `groupReach` past its ends, from `haloInset` inside them (owner, 2026-11-13: R48 of research/blur §7h).
        package static let groupReach = Space.xl + 3 * Space.xxl
        package static let groupFall = Size.bar + Space.xxl
        /// Under a group, far less than under a whole bar: the page reads through it (owner, 2026-11-13: 8 was too blurry).
        package static let groupRadius = 1.0

        /// The recipe for a group's blur layer of `size` (its outsets included).
        package static func group(size: CGSize, margin: Double, top: Bool) -> BlurRecipe {
            scaled(
                .variable(
                    radius: groupRadius,
                    mask: .under(
                        top: top,
                        width: size.width,
                        height: size.height,
                        solid: margin + Size.bar,
                        endFade: groupReach + haloInset
                    )
                )
            )
        }

        /// The tab bar's row of capsules, at the tabs' trailing end before +: a little fully blurred, then a fall over a tab's
        /// end (owner, 2026-11-13).
        package static let tabEndSolid = Space.s
        package static let tabEndFade = Space.xxl + Space.l
        /// Softer than the sidebar's ends (owner, 2026-11-13).
        package static let tabEndRadius = 4.0
        /// Behind the command bar: the whole window out of focus, still readable as shapes, barely darker (owner, 2026-11-13:
        /// "soft focus" of research/blur command-variants).
        package static let backdropRadius = 3.0
        package static let backdropDarkening = -0.05

        /// A group's blur starts falling `haloInset` inside its ends (owner, 2026-11-13: start earlier, end shorter).
        package static let haloInset = Space.l

        package static func under(_ edge: BlurMask.Edge, solid: Double, fade: Double, radius: Double = barRadius)
            -> BlurRecipe
        {
            scaled(.variable(radius: radius, mask: .edge(edge, solid: solid, fade: fade)))
        }

        package static var commandBackdrop: BlurRecipe {
            var recipe = scaled(.uniform(radius: backdropRadius))
            recipe.brightness = backdropDarkening
            return recipe
        }

        /// The resolution every blur captures what is under it at, relative to the screen's: lower is cheaper and softer
        /// (owner, 2026-11-13: 1, 0.5 and 0.25 tried, 1 kept; research/blur §7n).
        package static let captureScale = 1.0

        private static func scaled(_ recipe: BlurRecipe) -> BlurRecipe {
            var recipe = recipe
            recipe.captureScale = captureScale
            return recipe
        }
    }
}
