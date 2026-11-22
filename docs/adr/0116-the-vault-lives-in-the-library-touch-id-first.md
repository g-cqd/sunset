---
status: accepted
date: 2026-11-22
---

# The vault lives in the Library; Touch ID first

## Context

A vault can be made, opened and unlocked (roadmap 0091). Where it is shown, and what making the first one asks, were
the owner's to choose (2026-11-22), among a Library section, a window of its own, and a Settings page; and Touch ID
first or a password first.

## Decision

- **Passwords is a section of the Library**, beside History, Documents and Downloads: the list in the sidebar, an entry
  opened in the pane area. Locked, the section shows how to unlock it. It is there only while `features.credentials` is on.
- **Touch ID first**: making the first vault sets Touch ID as the everyday factor, a master password as its fallback, and
  shows the recovery code once. On a Mac without Touch ID, the password is the factor.

## Consequences

- What is shown of the vault is in a window with everything else: capture exclusion applies to the panes and rows that
  show an entry, not to a window of its own.
- A Touch ID factor is bound to the fingers enrolled when it was set: one added later does not open the vault; the
  password does, and can set Touch ID again.
