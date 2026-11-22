---
status: accepted
date: 2026-11-22
---

# Saved logins stay offered across a site's hosts, the exact host first

## Context

`LoginMatch` offers a login on any host of the site it was saved for (the registrable domain, by the Public Suffix List),
the exact host first; never an https login on an http page. The outside audit of 2026-11-22 (MED-02) worried about a hostile
subdomain of a shared site. The owner chose (2026-11-22) to keep it.

## Decision

Unchanged: offered across the site's hosts, exact host first, filled only on the person's choice.

## Consequences

- As Safari and the common password managers behave. Shared hosting is separated by the Public Suffix List
  (`github.io`, …); a site that gives subdomains to strangers without being on the list is not.
