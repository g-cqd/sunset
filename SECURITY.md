# Security policy

Sunset is a native macOS terminal emulator, WebKit browser, document viewer, and credential vault. Treat every byte
coming from a terminal program, web page, browser extension, download, `.svault` backup, Markdown file, or update feed
as untrusted input.

## Reporting a vulnerability

Report vulnerabilities privately through GitHub's **Report a vulnerability** button on the Security tab — never in
public issues or pull requests. Please include:

- The Sunset build number (`About Sunset` or `CFBundleVersion`) and variant (Sunset WebKit or System WebKit).
- Minimal reproduction steps, byte sequence, HTML/Markdown sample, or extension package.
- What an attacker gains (impact & violated boundary in `docs/design/0006-threat-model.md`).

### Scope

- Memory-safety faults, crashes, or denial-of-service hangs from untrusted input.
- Escapes from policy boundaries (clipboard, Kitty graphics / pasteboard image limits, hyperlink schemes, paste guard,
  download quarantine, profile isolation, share/notification origin checks, extension CRX3/XPI verification).
- Vault cryptographic weaknesses, credential leaks, or updater verification / rollback / freeze bypasses.

## Response targets (SLAs)

| Milestone | Target |
|---|---|
| Private acknowledgement | Within **3 working days** |
| Initial triage & severity confirmation | Within **7 calendar days** |
| Fix & advisory — **Critical** | Within **7 calendar days** |
| Fix & advisory — **High** | Within **30 calendar days** |
| Fix — **Medium / Low** | Next scheduled release |

Security fixes in released builds are published with a GitHub Security Advisory (and CVE identifier where applicable)
and named in the release notes.

## Supported versions & verification

Only the latest release line receives security updates (including automated Sunset WebKit security rebuilds under
ADR-0127). Every official release ships:

- Developer ID signature, Hardened Runtime, and Apple notarisation.
- Mandatory Ed25519-signed expiring `release-index.json` + `.sig` (ADR-0125).
- CycloneDX 1.5 SBOM (`Sunset-<version>.sbom.cdx.json`) and GitHub SLSA Build Provenance attestations
  (`gh attestation verify <asset> --owner g-cqd`).
