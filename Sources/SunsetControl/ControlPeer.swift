internal import Darwin

/// Who asks over the control socket: the process at the other end, and the session it runs in. A session is what is
/// approved (`ControlServer`'s handler asks the person once per session): its leader, the shell of a terminal or the app
/// that started the tool, by its process id and the time it started, so that a process id used again is another session.
public struct ControlPeer: Sendable, Equatable {
    /// The session: its leader's process id and start time.
    public struct Session: Sendable, Hashable {
        public let leader: Int32
        public let started: Int64

        public init(leader: Int32, started: Int64) {
            self.leader = leader
            self.started = started
        }

        /// Whether its leader still runs: the same process id, started at the same time.
        public var isAlive: Bool {
            Session.started(leader) == started
        }

        /// When `pid` started, in microseconds since 1970; nil when there is no such process.
        static func started(_ pid: Int32) -> Int64? {
            var info = proc_bsdinfo()
            let size = Int32(MemoryLayout<proc_bsdinfo>.size)
            guard unsafe proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
            return Int64(info.pbi_start_tvsec) * 1_000_000 + Int64(info.pbi_start_tvusec)
        }
    }

    /// The process at the other end.
    public let pid: Int32
    /// Its program's path.
    public let path: String
    public let session: Session
    /// The session leader's program's name ("zsh", "Claude").
    public let leaderName: String
    /// The leader's program's path.
    public let leaderPath: String

    public init(pid: Int32, path: String, session: Session, leaderName: String, leaderPath: String) {
        self.pid = pid
        self.path = path
        self.session = session
        self.leaderName = leaderName
        self.leaderPath = leaderPath
    }

    /// The peer `pid`, read from the system; nil when it is gone.
    static func of(_ pid: Int32) -> Self? {
        let leader = getsid(pid)
        guard leader > 0, let started = Session.started(leader) else { return nil }
        return Self(
            pid: pid,
            path: path(pid),
            session: Session(leader: leader, started: started),
            leaderName: name(leader),
            leaderPath: path(leader)
        )
    }

    private static func path(_ pid: Int32) -> String {
        var buffer = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        let length = buffer.withUnsafeMutableBufferPointer {
            unsafe proc_pidpath(pid, $0.baseAddress, UInt32($0.count))
        }
        guard length > 0 else { return "" }
        return String(decoding: buffer.prefix(Int(length)).map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    private static func name(_ pid: Int32) -> String {
        var buffer = [CChar](repeating: 0, count: 256)
        let length = buffer.withUnsafeMutableBufferPointer { unsafe proc_name(pid, $0.baseAddress, UInt32($0.count)) }
        guard length > 0 else { return "process \(pid)" }
        return String(decoding: buffer.prefix(Int(length)).map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }
}
