# Security policy

A terminal emulator parses untrusted bytes from every program it hosts, and a few of its escape sequences can act: reading or writing the clipboard, reading files for image display,
opening links, setting titles, answering queries, injecting text. Treat anything beyond drawing as a security surface.

Report vulnerabilities privately through GitHub's *Report a vulnerability* button on the Security tab, not in public issues. Include the revision, the byte sequence or program that
triggers it, and what an attacker gains. In scope: memory-safety faults or hangs from crafted input, escapes from a policy (clipboard, file reads by graphics commands, hyperlink schemes,
paste, title/notification injection), and credential or file exposure through the control socket.

The policy surface is specified in the white paper (§9) and will be an ADR before the first such feature is implemented.
