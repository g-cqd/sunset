import Testing

@testable import SunsetCore

@Suite("OSC 7, 9, 99, 133, 777, 1337 (ADR-0010)") struct OSCHostStateTests {
    private func feed(_ text: String, columns: Int = 20, rows: Int = 4, limit: Int = 100) -> Terminal {
        var t = Terminal(columns: columns, rows: rows, scrollbackLimit: limit)
        t.feed(text)
        return t
    }

    // MARK: Notifications

    @Test func `OSC 9 is a notification with a body`() {
        var t = feed("\(esc)]9;Build finished\u{07}")
        #expect(t.takeEvents() == [.notification(title: "", body: "Build finished")])
    }

    @Test func `OSC 777 notify has a title and a body`() {
        var t = feed("\(esc)]777;notify;Done;All tests pass\u{07}")
        #expect(t.takeEvents() == [.notification(title: "Done", body: "All tests pass")])
        var other = feed("\(esc)]777;preexec\u{07}")
        #expect(other.takeEvents().isEmpty, "other OSC 777 commands are not notifications")
    }

    @Test func `OSC 99 takes its payload as the title, or the body when it says so`() {
        var t = feed("\(esc)]99;;Hello\u{07}")
        #expect(t.takeEvents() == [.notification(title: "Hello", body: "")])
        var body = feed("\(esc)]99;p=body;Only a body\u{07}")
        #expect(body.takeEvents() == [.notification(title: "", body: "Only a body")])
    }

    @Test func `OSC 99 pieces with one id are one notification, shown when the last says it is done`() {
        var t = feed("\(esc)]99;i=7:d=0;Title\u{07}\(esc)]99;i=7:p=body;The body\u{07}")
        #expect(t.takeEvents() == [.notification(title: "Title", body: "The body")])
    }

    @Test func `OSC 99 can send its text base64 encoded`() {
        var t = feed("\(esc)]99;e=1;SGk=\u{07}")
        #expect(t.takeEvents() == [.notification(title: "Hi", body: "")])
    }

    @Test func `a notification loses control characters and is cut to 256 and 1024 bytes`() {
        var t = feed("\(esc)]777;notify;a\u{01}b\u{7F}c;\(String(repeating: "é", count: 600))\u{07}")
        let taken = t.takeEvents()
        guard case .notification(let title, let body)? = taken.first else {
            Issue.record("no notification")
            return
        }
        #expect(title == "abc")
        #expect(body.utf8.count <= 1024 && body.utf8.count > 1000)
        #expect(body.unicodeScalars.allSatisfy { $0 == "é" }, "cut at a character, not in the middle of one")
    }

    @Test func `a notification with nothing to show is dropped`() {
        var t = feed("\(esc)]9;\u{07}\(esc)]777;notify;;\u{07}")
        #expect(t.takeEvents().isEmpty)
    }

    @Test func `no notification query gets a reply`() {
        var t = feed("\(esc)]99;i=1:p=?;\u{07}")
        #expect(t.takeReplies().isEmpty)
    }

    // MARK: Progress

    @Test func `OSC 9;4 sets the progress state`() {
        #expect(feed("\(esc)]9;4;1;50\u{07}").screen.progress == .normal(percent: 50))
        #expect(feed("\(esc)]9;4;2;75\u{07}").screen.progress == .error(percent: 75))
        #expect(feed("\(esc)]9;4;3\u{07}").screen.progress == .indeterminate)
        #expect(feed("\(esc)]9;4;4;10\u{07}").screen.progress == .paused(percent: 10))
        #expect(feed("\(esc)]9;4;1;50\u{07}\(esc)]9;4;0\u{07}").screen.progress == .hidden)
        #expect(feed("\(esc)]9;4;1\u{07}").screen.progress == .normal(percent: 0))
    }

    @Test func `a progress that makes no sense leaves the state as it was, and is not a notification`() {
        var t = feed("\(esc)]9;4;1;50\u{07}\(esc)]9;4;1;101\u{07}\(esc)]9;4;9;5\u{07}\(esc)]9;4;1;x\u{07}")
        #expect(t.screen.progress == .normal(percent: 50))
        #expect(t.takeEvents().isEmpty)
    }

    // MARK: Working directory

    @Test func `OSC 7 records the host and the decoded path`() {
        #expect(
            feed("\(esc)]7;file://mac.local/Users/me/a%20b\u{07}").screen.workingDirectory
                == WorkingDirectory(host: "mac.local", path: "/Users/me/a b")
        )
        #expect(
            feed("\(esc)]7;file:///tmp\(esc)\\").screen.workingDirectory == WorkingDirectory(host: "", path: "/tmp")
        )
    }

    @Test func `OSC 7 refuses what is not an absolute file path without control characters`() {
        let ok = "\(esc)]7;file:///tmp\u{07}"
        for bad in [
            "http://x/y", "file://host", "file:///a/%00b", "file:///a/%0Ab", "file://h/a/%1Bb", "file://h/a%",
            "relative/path", "file:///a/%zz"
        ] {
            #expect(
                feed(ok + "\(esc)]7;\(bad)\u{07}").screen.workingDirectory == WorkingDirectory(host: "", path: "/tmp"),
                "\(bad)"
            )
        }
    }

    @Test func `the working directory is never reported back`() {
        var t = feed("\(esc)]7;file:///tmp\u{07}\(esc)]7;?\u{07}")
        #expect(t.takeReplies().isEmpty)
    }

    @Test func `iTerm's CurrentDir sets the directory too`() {
        #expect(
            feed("\(esc)]1337;CurrentDir=/Users/me\u{07}").screen.workingDirectory
                == WorkingDirectory(host: "", path: "/Users/me")
        )
        #expect(feed("\(esc)]1337;CurrentDir=rel\u{07}").screen.workingDirectory == nil)
    }

    // MARK: Prompt marks

    @Test func `OSC 133 A B C D are marks on the line the cursor is on`() {
        let t = feed("one\r\n\(esc)]133;A\u{07}$ \(esc)]133;B\u{07}ls\r\n\(esc)]133;C\u{07}out\r\n\(esc)]133;D;0\u{07}")
        #expect(
            t.screen.promptMarks == [
                PromptMark(kind: .promptStart, stableLine: 1),
                PromptMark(kind: .commandStart, stableLine: 1),
                PromptMark(kind: .outputStart, stableLine: 2),
                PromptMark(kind: .commandEnd, stableLine: 3, exitStatus: 0)
            ]
        )
    }

    @Test func `the exit status is a number 0 to 255 or nothing`() {
        func status(_ text: String) -> Int?? {
            feed("\(esc)]133;D\(text)\u{07}").screen.promptMarks.first.map { $0.exitStatus }
        }
        #expect(status(";130") == .some(130))
        #expect(status("") == .some(nil))
        #expect(status(";256") == .some(nil))
        #expect(status(";-1") == .some(nil))
        #expect(status(";abc") == .some(nil))
        #expect(status(";7;aid=3") == .some(7))
    }

    @Test func `options on a mark are ignored and an unknown letter is not a mark`() {
        #expect(
            feed("\(esc)]133;A;aid=5;k=s\u{07}").screen.promptMarks == [PromptMark(kind: .promptStart, stableLine: 0)]
        )
        #expect(feed("\(esc)]133;Z\u{07}\(esc)]133;\u{07}").screen.promptMarks.isEmpty)
    }

    @Test func `iTerm's SetMark is a prompt mark`() {
        #expect(feed("\(esc)]1337;SetMark\u{07}").screen.promptMarks == [PromptMark(kind: .promptStart, stableLine: 0)])
    }

    @Test func `marks keep their line while the history rolls, and report where it is now`() {
        var t = feed("\(esc)]133;A\u{07}first", rows: 4, limit: 3)
        guard let stable = t.screen.promptMarks.first?.stableLine else {
            Issue.record("no mark")
            return
        }
        #expect(t.screen.absoluteLine(ofStable: stable) == 0)
        t.feed("\r\n1\r\n2\r\n3")
        #expect(t.screen.scrollbackCount == 0)
        #expect(t.screen.absoluteLine(ofStable: stable) == 0)
        t.feed("\r\n4\r\n5")
        #expect(t.screen.scrollbackCount == 2 && t.screen.absoluteLine(ofStable: stable) == 0)
        t.feed("\r\n6\r\n7\r\n8")
        #expect(t.screen.scrollbackCount == 3)
        #expect(t.screen.absoluteLine(ofStable: stable) == nil, "dropped from the history")
    }

    @Test func `no more than 4096 marks are kept, the newest`() {
        let t = feed((0 ..< 5000).map { _ in "\(esc)]133;A\u{07}" }.joined())
        #expect(t.screen.promptMarks.count == 4096)
    }
}
