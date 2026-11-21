# How a welcome is supposed to be made, and where ours fails

The owner, 2026-11-21: "please research how good interfaces are supposed to be made because yours is shit". Sources: Apple's
Human Interface Guidelines (Onboarding, Launching, Layout, Typography, Materials, Color, Buttons, Motion) and the WWDC25
sessions *Meet Liquid Glass* (219) and *Get to know the new design system* (356). What they say is theirs, quoted or close;
the verdicts on our welcome (as recorded on 2026-11-21, `/tmp/sunset-welcome.mov`) are ours.

## What the guidance says

| Topic | Guidance (source) |
|---|---|
| Onboarding | "fast, fun, and optional"; "brief, enjoyable … doesn't require people to memorize a lot"; "postpone nonessential setup flows or customization steps. Provide reasonable default settings"; teach by doing, prefer tips in context over one flow; if skipped, never shown again but findable (HIG Onboarding) |
| Splash | "Briefly display a splash screen if necessary … just long enough for people to absorb the information at a glance without feeling that it's delaying their experience" (HIG Onboarding); on macOS a splash belongs at the start of onboarding (HIG Launching) |
| Motion | "purposefully, supporting the experience without overshadowing it"; "let people cancel motion … don't make people wait for an animation to complete"; motion optional (Reduce Motion) (HIG Motion) |
| Typography | system text styles, not fixed sizes (they follow the person's text size); hierarchy by weight, size, colour; the new system's typography is "bolder and left-aligned to improve readability in key moments like alerts and onboarding" (WWDC25 356) |
| Layout | order by importance, reading order from the top leading corner; align to scan; group with space rather than decoration; "hierarchy should be expressed through layout and grouping", not added backgrounds or borders (356) |
| Liquid Glass | a functional layer for controls, above content; "Don't use Liquid Glass in the content layer"; "use Liquid Glass effects sparingly"; clear glass only over rich backgrounds, with a 35% dimming layer if the content is bright (HIG Materials) |
| Colour on glass | glass has no colour of its own; tint only to emphasise one primary action; "avoid applying a similar color to button labels and content layer backgrounds … prefer the default monochromatic appearance" (HIG Buttons, Color) |
| Buttons | one or two prominent buttons a view; the primary role answers Return; distinguish the preferred option by style, not size (HIG Buttons) |
| Shapes | concentric: radii nest around a shared centre; on macOS large controls are capsules, smaller ones rounded rectangles (356) |
| Controls | standard components carry glass, states, accessibility; toggles and sliders take on glass when used (HIG Materials) |

## Where our welcome fails it

| What we did | Against |
|---|---|
| Seven pages; security model and what opens at start asked up front | "postpone nonessential setup … reasonable defaults": both have good defaults and live in Settings |
| A 5 s opening the person must sit through, not cancellable | Motion: let people cancel; Splash: at a glance |
| Titles centred, fixed point sizes (32, 15, 12) | left-aligned, bolder onboarding text; system text styles |
| Choices as hand-made rows, the unchosen at 60% opacity | low contrast reads as disabled; standard toggles and pickers carry state and accessibility |
| Hand-drawn page dots, a text "Skip" at low contrast | decoration instead of layout; a control too faint to find |
| A Continue tinted orange over a pink sky (seen washed out) | tint that matches the content; prefer monochrome glass over colourful content |
| Text set straight on the brightest part of the sky | legibility: dim behind text, or place it over the darker sky |
| The opening's shape morphing from a circle to the window | (the owner) the sun and the sky are separate things and should move in their own phases; the window should appear by fade and focus, not by a moving outline |

## What follows from it (proposal)

1. The opening: the sun alone first, fading in out of focus, slowly; then the sky, its own phase, lighting up around the
   sun; the window comes into focus where it stands (opacity and blur), never a travelling outline. A click or a key
   ends it at once. Reduce Motion: a cross-fade.
2. Fewer questions: what Sunset is for (terminal, web, documents: toggles), the default browser, the import. Security and
   start keep their defaults and are named, with a link, as "in Settings".
3. One page, or two at most; text left-aligned in the system's styles; native controls (toggles, a prominent Get Started,
   the rest plain glass); a dimming gradient where text sits on the sky.

Point 2 departs from note n75 (which asked for the security model and the start behaviour): the owner decides.
