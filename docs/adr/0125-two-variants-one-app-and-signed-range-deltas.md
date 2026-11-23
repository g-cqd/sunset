---
status: accepted
date: 2026-11-23
supersedes: ADR-0124; extends ADR-0122
---

# One app with two notarized variants, a single range-addressed delta archive, and a signed release index

## Context

ADR-0124 placed a downloadable WebKit engine in a folder beside `Sunset.app`. Under adversarial review and owner feedback:
- `LC_DYLD_ENVIRONMENT` only resolves paths relative to the executable, forcing a visible or dot-hidden folder beside
  `Sunset.app` (unacceptable clutter in Finder, and unwritable in `/Applications` for non-admin accounts).
- An external engine duplicates trust checks (per-framework online notarization checks), creates partial-install failure
  modes requiring a launch-time mixed-WebKit guard, and requires shipping XPC service shims inside the native app.

Meanwhile, shipping `N` separate `.update` files per flavour bloated alpha.12 to 14 release assets, lacked a size cutoff
or bounded decompression, did not pin download hosts, and ran O(N log N) suffix sort over unchanged 122 MB binaries.

Probed (diary 2026-11-23-13):
- `release-assets.githubusercontent.com` returns `501` on multi-range, ignores `If-Range` (must use `If-Match`), and
  issues SAS URLs expiring in ~42 minutes.
- Re-signed `WebCore` (122 MB) is 99.8% identical at matching offsets.
- Sharing one `WKWebsiteDataStore` across Sunset's WebKit → System WebKit silently breaks IndexedDB reads on downgrade.

## Decision

1. **One app (`studio.aemi.sunset`), two complete notarized variants:**
   - **Native** (system WebKit, no bundled frameworks) and **WebKit** (bundled Sunset WebKit + XPC services inside
     `Sunset.app`, using ADR-0123's `LC_DYLD_ENVIRONMENT`). Both share `studio.aemi.sunset`, the same provisioning profile
     and Keychain access group (vault Touch ID/Keychain and macOS permissions survive switching).
   - **Per-variant `WKWebsiteDataStore`:** the WebKit variant derives deterministic per-variant store UUIDs so downgrading
     to system WebKit never silently loses IndexedDB data, and switching back restores WebKit sessions intact.
   - Switching engine in Settings › General › Updates ("System" vs. "Sunset's") downloads the other variant through the
     updater (using a same-build delta) and swaps `Sunset.app` atomically on restart. "Delete engine" switches back to
     Native.
   - Remove the external `SunsetEngine` folder machinery (`EngineFolder`, `EngineCheck`, `EnginePlace`, `EngineManifest`,
     `AppEngine`, `make-engine-archive.sh`, XPC services in the native build).

2. **One range-addressed delta archive (`SSDLTA2`) per variant per release:**
   - Asset name: `<Flavour>-<tag>-build<N>-macos-<arch>.deltas`.
   - Fixed header (`"SSDLTA2\0"`, `tocLength`, `tocSHA256`) + LZMA-compressed JSON TOC at offset 0 (fetched via one
     `Range: bytes=0-65535` request) + one contiguous payload region per supported source build.
   - **Caps:** at most `K = 3` previous builds of the same variant, plus the same build of the other variant (for
     switching). Drop any source build whose delta exceeds 65% of the full zip; store a compressed full file whenever a
     per-file delta is not smaller.
   - Client checks local files against `baseSHA256` before fetching any payload bytes, then fetches its single contiguous
     range with `If-Match: <ETag>`, re-resolving on `403`, streaming progress, and falling back to the full zip on any
     error.

3. **Signed release index (`release-index.json` + `.sig`):**
   - Signed with an Ed25519 key kept on the signing Mac; Sunset embeds both the main public key and an offline backup
     public key.
   - Covers `toBuild`, `tag`, `notesSHA256`, and for each variant: `archiveName`, `archiveSize`, `archiveSHA256`,
     `deltasName`, `deltasSize`, `deltasTOCSHA256`.
   - Verified with CryptoKit **before** JSON, LZMA, or `BinaryDelta` processes any downloaded bytes.

4. **Defense-in-depth hardening:**
   - Streaming bounded LZMA decompression (`compression_stream`) with hard per-file (256 MiB) and total (1 GiB) caps.
   - Reject duplicate manifest paths, non-relative or escaping symlink targets, and `O_NOFOLLOW` reads from the running
     bundle.
   - Allow only `https://github.com/g-cqd/sunset/` and GitHub's asset CDN hosts over HTTPS (unless `SUNSET_UPDATES_FEED`
     is set for local tests).
   - Common-prefix/suffix stripping in `BinaryDelta.make` for fast re-signed binary diffs.
   - Final install gate remains Apple Developer ID + Team ID + `studio.aemi.sunset` + Notarized + `staged.build > running`
     (or `staged.build == running` strictly when switching variant).

## Consequences

- `Sunset WebKit.app` (`studio.aemi.sunset.webkit`) is retired once the first two-variant release is verified end to end
  (existing users get a release note; their old data remains untouched under its old container).
- Every release has at most 5–6 assets instead of 14+, and switching engines is one click with zero files outside
  `Sunset.app`.
