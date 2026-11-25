# Sunset

A native macOS workspace combining a terminal emulator, WebKit browser tabs, and native Markdown/Mermaid/text documents in one window with Spaces, split panes, profiles, and an encrypted local store.

## Features

- **Terminal:** platform-free VT parser, screen model, and pseudo-terminal host with CPU and Metal GPU renderers and C/NEON pixel kernels.
- **Web:** system WebKit tabs with history, downloads, per-site permissions, content blocking, private windows, and WebKit extensions.
- **Documents:** native Markdown, Mermaid, and text viewing/editing for disk files or encrypted local notes with block-level disk merge.
- **Workspace:** sidebar or tab bar, splits, Spaces with isolated profiles, Favorites and Pinned grids, Library, and command bar.
- **Encrypted local store:** state database, local documents, and at-rest WebKit storage sealed with keys protected by the macOS Data Protection Keychain and Secure Enclave.

## Requirements

- macOS 26+
- Swift 6.4+ / Xcode 27+

## Building & Testing

```sh
swift test
```

## Architecture

- `SunsetCore` / `SunsetHost`: headless VT terminal core and PTY host
- `SunsetRender` / `SunsetRenderMac` / `SunsetRenderMetal` / `CSunsetKernels`: CPU reference renderer, CoreText glyphs, Metal renderer, and NEON/scalar pixel kernels
- `SunsetTerminalModel` / `SunsetTerminal`: terminal pane model and AppKit view
- `SunsetPane` / `SunsetShellModel` / `SunsetShell`: pure window/tab/Space models and SwiftUI/AppKit shell
- `SunsetStorage` / `SunsetSiteData`: encrypted store, Keychain/Secure Enclave key management, and site data

## Documentation

- [Design Documents](docs/design/)
- [Quality Gates](docs/quality.md)
- [Architecture Decisions](docs/adr/)
- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)

## License

[MIT](LICENSE)
