# Administrator Hardening & Release Key Custody Guide

Status: **accepted** (R-OPS-2, R-OPS-3, R-SC-5).

## 1. Enterprise Managed Preferences (MDM)

Administrators can enforce Sunset's security posture via a macOS configuration profile targeting Sunset's bundle
identifier (`studio.aemi.sunset`). Sunset reads **only** administrator-forced keys
(`UserDefaults.objectIsForced(forKey:)` via `SunsetConfig.ManagedPolicy`); local `defaults write` values never count
as policy, and malformed forced values fail closed.

| Key | Type | Effect when forced |
|---|---|---|
| `AllowExtensions` | Boolean (`false`) | Forbids installing/loading browser extensions |
| `AllowCertificateExceptions` | Boolean (`false`) | Forbids per-certificate TLS exceptions |
| `RequireHardenedWeb` | Boolean (`true`) | Clamps `web.hardening` away from `.off` to `.noJIT` |
| `RequireHTTPSUpgrade` | Boolean (`true`) | Clamps `web.httpsUpgrade` away from `.off` to `.fallback` |
| `AllowSafeDownloadAutoOpen` | Boolean (`false`) | Forces `web.openSafeDownloads = false` |
| `MaxVaultLockMinutes` | Number (`1…60`) | Caps `passwords.lockAfter` idle timeout (invalid values clamp to `5` minutes) |
| `RequireAutomaticUpdates` | Boolean (`true`) | Forces `updates.automatic = true` |

## 2. Security Event Log (SIEM Export)

`SunsetStorage.SecurityAuditLog` writes bounded (1 MiB, auto-rotated to `.1.jsonl`), `0600`, single-line JSONL records
containing ISO-8601 timestamps, event kind (`vault.unlocked`, `vault.unlock_failed`, `vault.backup_exported`,
`web.certificate_exception_granted`, `web.extension_refused`, `update.verified`, `update.refused`, `policy.enforced`),
outcome, and bounded non-secret attributes (never passwords, cookies, tokens, or URL query strings).

## 3. Release Verification & Key Custody Procedure (R-SC-5 / R-UPD-4)

Every official Sunset release ships:
1. Developer ID signature, Hardened Runtime (without `allow-dyld-environment-variables`), and Apple notarisation.
2. Mandatory Ed25519-signed expiring `release-index.json` + `.sig` (45-day lifetime, builds ≥ 829).
3. CycloneDX 1.5 SBOM (`Sunset-<version>.sbom.cdx.json`) naming every SwiftPM dependency plus the exact Sunset WebKit
   base commit and patch series.
4. GitHub SLSA Build Provenance attestations verifiable via:
   ```sh
   gh attestation verify Sunset-<version>-webkit-arm64.zip --owner g-cqd
   ```

### Key custody & rotation
- **Online release-index key (`release-index-main`):** Stored exclusively in a protected GitHub Environment secret
  (`RELEASE_INDEX_KEY`) or hardware-backed signing host (`0600`), never committed to git and never shared with PR jobs.
- **Offline backup / rotation key (`release-index-backup`):** Stored offline off all build hosts; embedded alongside
  the main key in `ReleaseIndex.trustedPublicKeys`.
- **Rotation / compromise response:**
  1. Revoke the compromised main key from GitHub Secrets and signing hosts immediately.
  2. Generate a new Ed25519 keypair, replace the compromised public key in `ReleaseIndex.trustedPublicKeys`, and sign
     the transition release with the offline backup key so existing builds accept it seamlessly.
  3. Ship the next release signed by the new main key and retire the backup key only after the transition window closes.
- **Clean-Mac disaster recovery drill:** Periodically test restoring a sealed `.svault` backup + recovery code / QR
  emergency sheet on a clean macOS user account to verify end-to-end vault recoverability independently of Keychain sync.
