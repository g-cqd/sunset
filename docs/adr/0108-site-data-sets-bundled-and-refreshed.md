---
status: accepted
date: 2026-11-20
---

# 0108 — The site data sets are bundled and refreshed

## Context

Credentials and security need two data sets (white paper §8, design 0007 open question 3): the Public Suffix List (which part of
an address is the site, so a password saved for `a.example.co.uk` is not offered on `b.co.uk`) and Apple's
password-manager-resources (each site's password rules, shared logins, change-password pages). Both change over time.

## Decision

The owner, 2026-11-20: each is **built into the app as a fallback**, and **fetched and cached** to update it. A fetched copy
replaces the bundled one only when it parses and is newer; a failed or partial fetch leaves the last good copy in use.

## Consequences

- Sunset works offline and on first launch with the copy it shipped with.
- A fetch is a network request Sunset makes on its own: it needs its policy and test (white paper §9): which host, how often,
  that it carries no identifier, and that it can be turned off.
- Each release refreshes the bundled copies; their source and date are recorded beside them.
- Not built yet: lands with roadmap 0091–0094 (credentials) where the data is first read.
