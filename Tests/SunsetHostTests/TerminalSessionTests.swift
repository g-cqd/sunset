import SunsetCore
import Testing

@testable import SunsetHost

/// Waits for `condition` to hold on a fresh snapshot after each update, for at most `seconds` (a bound on how long a failing test takes, not a wait that
/// a passing one depends on).
private func waitFor(_ session: TerminalSession, seconds: Int = 10, _ condition: @escaping @Sendable (Screen) -> Bool)
    async -> Bool
{
    await withTaskGroup(of: Bool.self) { group in
        group.addTask {
            if condition(await session.takeSnapshot()) { return true }
            for await update in session.updates {
                if case .closed = update { return condition(await session.takeSnapshot()) }
                if condition(await session.takeSnapshot()) { return true }
            }
            return false
        }
        group.addTask {
            try? await Task.sleep(for: .seconds(seconds))
            return false
        }
        let first = await group.next() ?? false
        group.cancelAll()
        return first
    }
}

private func started(_ script: String, columns: Int = 80, rows: Int = 24) async throws -> TerminalSession {
    let session = try TerminalSession(["/bin/sh", "-c", script], columns: columns, rows: rows)
    await session.start()
    return session
}

@Suite("Terminal session (actor)", .serialized) struct TerminalSessionTests {
    @Test func `output reaches the screen`() async throws {
        let session = try await started("printf 'hello\\r\\nworld'")
        #expect(await waitFor(session) { $0.text(row: 1) == "world" })
        #expect(await session.takeSnapshot().text(row: 0) == "hello")
    }

    @Test func `the terminal's replies and keys reach the program, in order`() async throws {
        let session = try await started(
            "stty raw -echo; printf '\\033[5n'; dd bs=1 count=4 2>/dev/null | od -An -tx1; read line; echo got:$line"
        )
        #expect(
            await waitFor(session) { $0.text(row: 0).split(separator: " ").joined(separator: " ") == "1b 5b 30 6e" }
        )
        await session.send(Array("a".utf8))
        await session.send(Array("bc\n".utf8))
        #expect(
            await waitFor(session) { screen in
                (0 ..< screen.rows).contains { screen.text(row: $0).hasSuffix("got:abc") }
            }
        )
    }

    @Test func `a mouse event reaches the program only when it asked for the mouse, in the format it chose`()
        async throws
    {
        let session = try await started(
            "stty raw -echo; sleep 1; printf '\\033[?1000h\\033[?1006h'; dd bs=1 count=9 2>/dev/null | od -An -tx1"
        )
        let press = MouseEvent(.press, .left, column: 1, row: 2)
        #expect(await session.send(press) == false, "the program has not asked for the mouse yet")
        #expect(await waitFor(session) { $0.modes.mouseTracking == .normal && $0.modes.mouseFormat == .sgr })
        #expect(await session.send(press) == true)
        #expect(
            await waitFor(session) {
                $0.text(row: 0).split(separator: " ").joined(separator: " ") == "1b 5b 3c 30 3b 32 3b 33 4d"
            }
        )
    }

    @Test func `on the alternate screen with alternate scroll on, the wheel is the arrow keys`() async throws {
        let session = try await started(
            "stty raw -echo; printf '\\033[?1049h\\033[?1007h'; dd bs=1 count=6 2>/dev/null | od -An -tx1"
        )
        #expect(await waitFor(session) { $0.isAlternate && $0.modes.alternateScroll })
        let up = MouseEvent(.press, .wheelUp, column: 1, row: 1)
        let down = MouseEvent(.press, .wheelDown, column: 1, row: 1)
        #expect(await session.send(up) == true, "the program has the wheel now")
        #expect(await session.send(down) == true)
        #expect(
            await waitFor(session) {
                $0.text(row: 0).split(separator: " ").joined(separator: " ") == "1b 5b 41 1b 5b 42"
            }
        )
    }

    @Test func `the wheel on the primary screen with no mouse tracking is left to the window`() async throws {
        let session = try await started("sleep 3")
        #expect(await session.send(MouseEvent(.press, .wheelUp, column: 1, row: 1)) == false)
    }

    @Test func `what the program asks of the host arrives as events, in order, once`() async throws {
        let session = try await started(
            "printf '\\033]52;c;aGk=\\007\\033]9;done\\007'; sleep 1"
        )
        var seen: [HostEvent] = []
        for await event in session.hostEvents {
            seen.append(event)
            if seen.count == 2 { break }
        }
        #expect(seen == [.clipboardWrite("hi"), .notification(title: "", body: "done")])
    }

    @Test func `a resize reaches the program and the screen`() async throws {
        let session = try await started("stty size; read x; stty size")
        #expect(await waitFor(session) { $0.text(row: 0) == "24 80" })
        await session.resize(columns: 100, rows: 30)
        await session.send(Array("\n".utf8))
        #expect(await waitFor(session) { $0.text(row: 2) == "30 100" })
        #expect(await session.takeSnapshot().columns == 100)
    }

    @Test func `the end of the program is an update with its exit status`() async throws {
        let session = try await started("exit 3")
        var closed: TerminalSession.Update?
        for await update in session.updates {
            if case .closed = update { closed = update }
        }
        guard case .closed(let status)? = closed else {
            Issue.record("no closed update")
            return
        }
        #expect(status == 3)
        #expect(await session.isClosed)
    }

    @Test func `a snapshot passes the dirty marks to its taker`() async throws {
        let session = try await started("printf 'one\\r\\ntwo'; read x; printf '\\033[1;1Hchanged'; read y")
        #expect(await waitFor(session) { $0.text(row: 1) == "two" })
        // The wait took snapshots; what changed since the last one is what the next one shows.
        let quiet = await session.takeSnapshot()
        #expect((0 ..< quiet.rows).allSatisfy { !quiet.isDirty(row: $0) })
        await session.send(Array("\n".utf8))
        #expect(await waitFor(session) { $0.text(row: 0) == "changed" })
        let after = await session.takeSnapshot()
        #expect((0 ..< after.rows).allSatisfy { !after.isDirty(row: $0) })
    }

    @Test func `a flood of output is all processed and the updates coalesce`() async throws {
        let session = try await started("seq 1 60000")
        var changes = 0
        for await update in session.updates {
            if case .changed = update { changes += 1 }
        }
        let screen = await session.takeSnapshot()
        #expect((0 ..< screen.rows).contains { screen.text(row: $0) == "60000" })
        #expect(screen.scrollbackCount == 10_000, "the history keeps its limit")
        #expect(changes >= 1)
    }

    @Test func `input to a child that does not read is bounded`() async throws {
        let session = try await started("sleep 30")
        let big = [UInt8](repeating: 0x61, count: 600_000)
        for _ in 0 ..< 4 { await session.send(big) }
        #expect(session.process.droppedSendCount > 0)
        await session.stop()
    }

    @Test func `stopping ends the reading and the program`() async throws {
        let session = try await started("sleep 30")
        await session.stop()
        var sawClosed = false
        for await update in session.updates {
            if case .closed = update { sawClosed = true }
        }
        #expect(sawClosed)
    }

    @Test func `the host's default colours reach the screen, and the consumer is told`() async throws {
        let session = try await started("sleep 5")
        await session.setDefaultColors(foreground: RGB(9, 8, 7), background: RGB(1, 2, 3), cursor: nil)
        let screen = await session.takeSnapshot()
        #expect(screen.palette.foreground == RGB(9, 8, 7))
        #expect(screen.palette.background == RGB(1, 2, 3))
        #expect(screen.hasDirtyRows, "the renderer is to draw the new colours")
        await session.stop()
    }
}
