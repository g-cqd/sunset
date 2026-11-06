import SunsetCore
import Testing

@testable import SunsetHost

private func sh(_ script: String, columns: Int = 80, rows: Int = 24, environment: [String: String] = [:]) throws
    -> HeadlessSession
{
    try HeadlessSession(["/bin/sh", "-c", script], columns: columns, rows: rows, environment: environment)
}

@Suite("Headless session", .serialized) struct HeadlessSessionTests {
    @Test func `a program's output reaches the screen`() throws {
        let session = try sh("printf 'hello\\r\\nworld'")
        #expect(session.wait { $0.screen.text(row: 1) == "world" })
        #expect(session.lines[0] == "hello")
        #expect(session.waitForExit())
    }

    @Test func `the child has a session of its own with the terminal as its controlling terminal`() throws {
        let session = try sh("ps -o tty= -p $$")
        #expect(session.wait { $0.screen.text(row: 0).hasPrefix("ttys") })
    }

    @Test func `the terminal is the controlling terminal and the child's group is its foreground group`() throws {
        // What job-control shells need (fish refused to start without it): tcgetpgrp works on stdin and /dev/tty can be opened.
        let session = try sh(
            "/usr/bin/perl -e 'use POSIX; print POSIX::tcgetpgrp(0) == getpgrp() ? \"foreground\" : \"not\"; print open(my $t, \"<\", \"/dev/tty\") ? \" devtty\" : \" nodevtty\"'"
        )
        #expect(session.wait { $0.screen.text(row: 0) == "foreground devtty" })
    }

    @Test func `the window size is the one asked for, and a resize reaches the program`() throws {
        let session = try sh("stty size; read x; stty size", columns: 80, rows: 24)
        #expect(session.wait { $0.screen.text(row: 0) == "24 80" })
        session.resize(columns: 100, rows: 30)
        try session.send("\n")
        #expect(session.wait { $0.screen.text(row: 2) == "30 100" })
        #expect(session.terminal.screen.columns == 100)
    }

    @Test func `the terminal's replies reach the program`() throws {
        let session = try sh("stty raw -echo; printf '\\033[5n'; dd bs=1 count=4 2>/dev/null | od -An -tx1")
        // od pads its columns; what matters is the four bytes of ESC [ 0 n.
        let ok = session.wait { $0.screen.text(row: 0).split(separator: " ").joined(separator: " ") == "1b 5b 30 6e" }
        #expect(ok, "screen: \(session.lines.prefix(3))")
    }

    @Test func `keys reach the program`() throws {
        let session = try sh("read line; echo got:$line")
        try session.send("abc\n")
        #expect(
            session.wait { terminal in
                (0 ..< terminal.screen.rows).contains { terminal.screen.text(row: $0) == "got:abc" }
            }
        )
    }

    @Test func `the exit status is reported`() throws {
        let session = try sh("exit 3")
        #expect(session.waitForExit())
        #expect(session.process.exitStatusBlocking(waitingUpTo: 5000) == 3)
    }

    @Test func `the environment names the terminal and can be extended`() throws {
        let session = try sh("echo $TERM $COLORTERM $FOO", environment: ["FOO": "bar"])
        #expect(session.wait { $0.screen.text(row: 0) == "xterm-256color truecolor bar" })
    }

    @Test func `a lot of output scrolls into the history`() throws {
        let session = try sh("seq 1 3000")
        #expect(session.waitForExit())
        #expect(session.terminal.screen.scrollbackCount > 2900 - 24)
        #expect(session.lines.contains("3000"))
        #expect(session.terminal.screen.scrollbackText(line: 0) == "1")
    }

    @Test func `non-ASCII text passes through the terminal unchanged`() throws {
        let session = try sh("printf 'é日e\\xcc\\x81'")
        #expect(session.wait { $0.screen.text(row: 0) == "é日e\u{301}" })
    }

    @Test func `a program that does not exist is an error, not a hang`() {
        #expect(throws: PTYError.self) {
            _ = try HeadlessSession(["/nonexistent/program"])
        }
    }
}
