---
status: accepted
date: 2026-11-18
---

# 0078 — Our own WebKit only when it is shown better

The owner, 2026-11-18: "we do our own webkit if its shown to be more performant, safer, more efficient, and more reliable,
this directive needs to be persisted in the repo"; on its form: "we need to reassess the reliability, safety, convenience
and complexity of that".

## Decision

1. Sunset runs on the system's WebKit. A WebKit of our own (built, patched, bundled or downloaded: roadmap 0048) is adopted
   only when it is **shown**, by probes and measurements recorded in the diary, against the system's on the same harness, to
   be at once more performant, safer, more efficient and more reliable. A gain on one of them alone does not adopt it.
2. Safety includes keeping up with WebKit's security fixes: a fork that lags the system's is not safer.
3. Its form (a download at run time, a second build, or neither) is decided after a spike reassesses reliability, safety,
   convenience and complexity; nothing of it ships before that.

## Consequences

What only an own engine could do (choosing the resolver inside WebKit, patches) waits for that evidence; the network work
goes on the system's WebKit first (ADR-0079).
