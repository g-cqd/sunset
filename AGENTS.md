# Working in `sunset`

Native macOS terminal, WebKit browser, and document workspace (`g-cqd/sunset`).

## Engineering principles

- **Verify claims with executable checks.** Prove behaviour with tests, reference-pixel comparisons (Metal vs. CPU renderer), and real measurements.
- **Strictness.** Swift 6 language mode, strict memory safety, warnings as errors. Keep `SunsetCore`, `SunsetRender`, `SunsetPane`, and `SunsetShellModel` free of AppKit/SwiftUI.
- **Security & privacy.** Protect user data at rest with Keychain/Secure Enclave-wrapped keys, enforce hardened entitlements, and validate untrusted terminal/web/document inputs without trapping.
- **Quality gates.** Follow every enforced rule in `docs/quality.md`.
- **Factual documentation.** Keep `README.md`, `docs/design/`, `docs/adr/`, and `Package.swift` aligned with the current codebase—no roadmaps or diary logs.

## Commands

```sh
swift test
swift format lint --strict --recursive Sources Tests Package.swift
```
