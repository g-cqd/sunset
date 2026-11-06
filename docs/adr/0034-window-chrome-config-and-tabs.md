---
status: proposed
date: 2026-11-07
---

# 0034 — One tab model with three presentations; a JSON configuration watched without Dispatch; private blur APIs by run-time lookup

Roadmap 0017 has the requirements and the owner's answers. This ADR records the decisions that shape the code, as **proposed**: each is confirmed or changed by the stage that builds it.

## Decision

- **Sessions belong to a `TabStore`, not to windows.** Native tabs, the sidebar and the built-in tab bar are presentations of the same store; the presentation can change while the programs run.
- **Configuration is JSON** (`~/.config/sunset/config.json`, then `$XDG_CONFIG_HOME/sunset/config.json`), parsed with AemiJSON, decoded into one `Codable` value with defaults for every key; unknown keys are reported, not fatal; an invalid file leaves the previous configuration in force and the reason is shown.
- **Live reload without Dispatch**: kqueue (`EVFILT_VNODE`) on the file's directory and the file, on a `DedicatedThread`, re-armed after rename or delete (editors save atomically), debounced; changes are applied key by key from a diff, not by rebuilding the window.
- **Private APIs are allowed** (self-signed, notarised, GitHub): their names are not written in the binary as plain strings; they are resolved at run time through InternedStrings, each behind a check that the symbol exists, with a public fallback and a log line when it does not.
- **Tab mode is `none | native | internal`.** `internal` excludes the other two.
- **Transparent materials cost an alpha channel only when used.**

## Evidence

None yet: this is a proposal. Stage S1 will add the first tests (schema defaults, error messages, the watcher surviving an atomic save, a diff applied to a running terminal).
