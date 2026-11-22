---
status: in-progress
blocked-by: 0091
date: 2026-11-19
---

# 0092 — Entries: templates, typed fields, constraints, layout, notes, files, history

Research: docs/research/credentials/vault.md. ADR-0092 (proposed).

| Step | What | Status |
|---|---|---|
| A | The model: entries, sections, fields, types, constraints, templates (shipped and the person's), references; pure, under tests | done 2026-11-22 (`VaultEntry`, `EntryTemplate`, `FieldConstraint`; kept in the vault: `Vault+Entries`), but for references, which are a kind with nothing behind it yet |
| B | The editor: one renderer per field type, add / remove / move / rename fields, layout (sections, widths, hidden by default), constraints checked as typed | not-started |
| C | Notes (Markdown, AemiMarkdown); attachments (1 MiB sealed chunks, own key, limits, preview inside Sunset only) | not-started |
| D | History: versions by count or age; concealed fields' dated history; restore | not-started |
| E | The library: search (never concealed values; measured at 10,000), folders, tags, favourites, icons through the profile's store | not-started |
| F | The generator (characters, words, PIN; `passwordrules`); local health (reused, weak, old); a breach check only if turned on | not-started |

Not done: B–F; A's references.
