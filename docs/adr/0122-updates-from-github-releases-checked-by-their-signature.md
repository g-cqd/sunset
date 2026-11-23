---
status: proposed
date: 2026-11-23
---

# Updates come from GitHub releases, are trusted for their code signature, and arrive as deltas when they can

## Context

The owner asked for an update mechanism of our own, open source, using only GitHub (n135). Sunset is published as GitHub
releases: a notarized zip per flavour (Sunset, Sunset WebKit), its SHA-256, a note. Every release so far is a pre-release.

## Decision

- **Feed:** GitHub's releases list (`api.github.com/repos/g-cqd/sunset/releases`), read without an account (60 requests an
  hour per address; Sunset checks at most every few hours). The assets are fetched from `github.com/…/releases/download`,
  which takes ranges. No server of ours, no other feed to keep.
- **Trust:** what is installed is trusted for its code signature, not for where it came from: the staged app must satisfy
  `anchor apple generic and certificate leaf[subject.OU] = <our team> and identifier <this app's>`, be notarized (its
  ticket, or Gatekeeper's assessment), and carry a later build (`CFBundleVersion`) than the running one. A hijacked GitHub
  account cannot make that without our Developer ID, which never leaves the signing Mac. So no second signing key: the
  manifest and the deltas need no signature of their own; anything wrong in them ends in a failed check and the full zip.
- **Deltas:** per changed file, a binary delta of our own (bsdiff's idea: matches against the old file, differences and
  new bytes, compressed with Apple's Compression framework), published for the last few builds. When the running build has
  none, the full zip. Every file the delta makes is checked against the manifest's SHA-256 before the signature check.
- **Install:** a staging copy beside the app (same volume), swapped with the running one atomically (`renamex_np`
  `RENAME_SWAP`) once Sunset quits, then run again; the old copy to the Trash. An app it cannot write (another owner,
  translocated, read-only volume) is told so, with the way to the release.
- **Choice:** automatic updates on by default and can be turned off; the dialog shows every release's notes between the
  running build and the new one.

## Consequences

The release routine writes two more kinds of assets (manifest, deltas). The trust check is the same as the one macOS makes
for a first download, plus the team and the build order (no downgrade). Not covered: an update while the app is translocated.
