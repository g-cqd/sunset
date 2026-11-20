---
status: accepted
date: 2026-11-20
---

# Entries are typed fields from templates, free to differ

## Context

The owner, 2026-11-19: "entries in the database that you could customize the content and layout of, add or remove fields,
with various types and constraints, attaching notes and files". Research: docs/research/credentials/vault.md.

## Decision (proposed)

- **An entry:**
  - sections of fields, each field with a type, a name, a value and its constraints;
  - a Markdown note;
  - attachments;
  - tags, a folder;
  - its history.
- **Templates** are records too: shipped ones (Login, Card, Identity, Secure note, Licence, SSH key, Wi-Fi, Bank account,
  Passport, API key, Server) and the person's own.
  - An entry made from a template may add, remove, rename and move fields.
  - A template's change is applied to its entries only when the person says so.
- **Field types:**
  - text, multi-line, concealed, one-time code, URL (with a match rule each), email, phone;
  - number, money, date, month-year, time, choice, multiple choice, toggle;
  - card number, reference, file, SSH key, address.
  - Constraints: required, lengths, a pattern, ranges, Luhn, "in the future"; only `required` blocks a save.
- **Attachments:**
  - 1 MiB sealed chunks under a key of their own;
  - limits set by the person;
  - previewed inside Sunset only: never a decrypted file outside the vault without an export.
- **History:** every save keeps the version before it (by count or age); concealed fields keep their own dated history.

## Consequences

- KDBX round trips keep Sunset's types in a namespaced attribute.
- The editor is a settings-like page built from the template's description, one renderer per field type.
