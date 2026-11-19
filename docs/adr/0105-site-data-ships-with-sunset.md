---
status: accepted
date: 2026-11-20
---

# 0105 — The Public Suffix List and Apple's password-manager-resources ship with Sunset

## Context

Filling passwords (roadmap 0094) matches an entry to a page by its site: `accounts.example.co.uk` and `example.co.uk` are one
site, `co.uk` is nobody's. That needs the Public Suffix List. Generating a password a site accepts, offering logins across
domains that share them, and sending a person to a change-password page need Apple's password-manager-resources. Both are
data dependencies (white paper §8); the owner accepted them on 2026-11-19.

## Decision

- **A module, `SunsetSiteData`,** with no dependency on Sunset's own modules, so that it can move to Aemi unchanged. It holds:
  - the data as resources;
  - `PublicSuffixList` (rules, wildcards, exceptions, punycode decoded for matching);
  - `PasswordManagerResources` (password rules, shared logins, change-password pages).
- **The sources:**
  - the list from the one address it asks to be fetched from, keeping its MPL 2.0 header;
  - Apple's files with their MIT licence beside them.
- **Updates:** `Scripts/update-site-data.sh` updates both and records each source's revision and date in
  `Resources/SOURCES.md`. An update is a commit, checked by the list's own tests.
- **Loading:** each is read once and kept: the list in 22 ms (release, the median of seven reads), a look-up about 2.5 µs.

## Consequences

- Nothing uses the data yet: roadmap 0094 (filling) and 0092 (the generator) will.
- When it moves to Aemi, Sunset depends on Aemi's revision and drops the module. That needs a push to Aemi, which the
  owner decides.
