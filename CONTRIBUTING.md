# Contributing

Claims need probes, style is not negotiable, and gates run whether or not anyone watches.

1. Read the [white paper](docs/WHITE-PAPER.md) and [AGENTS.md](AGENTS.md).
2. Pick a [roadmap](docs/roadmap) entry, or open one.
3. Write the failing test first; observe that it fails for the right reason.
4. Measure if you touch a hot path. Compare against the oracle terminals on the same machine and harness.
5. Record decisions as ADRs and probes in the diary.
6. Commits are small and say *why*; the tip you hand back builds and passes (ADR-0007). Don't wait on CI; mutation testing is CI's.

Security issues: [SECURITY.md](SECURITY.md).
