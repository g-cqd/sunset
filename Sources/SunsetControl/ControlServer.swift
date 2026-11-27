internal import Darwin
import Foundation
import SunsetRuntime
import Synchronization

/// The app's end of the control socket: each connection sends request lines and is answered, line for line, by
/// `handle`, told who asks (`ControlPeer`). Off unless the app starts it (`control.enabled`). Its waits (for the next
/// connection, for a line) block a thread of their own (`DedicatedThread`), never one of the cooperative pool.
public final class ControlServer: Sendable {
    public typealias Handler = @Sendable (ControlRequest, ControlPeer) async -> ControlReply

    private let path: String
    private let listener: Mutex<UnixSocket?> = Mutex(nil)

    public init(path: String = ControlPath.standard) {
        self.path = path
    }

    /// Listens at its path, answering with `handle`, until `stop`.
    public func start(handle: @escaping Handler) throws {
        let socket = try UnixSocket.listening(at: path)
        listener.withLock { $0 = socket }
        let path = path
        let accepting = DedicatedThread.start()
        Runtime.live.detached(executorPreference: accepting) {
            while let connection = socket.accept() {
                let reading = DedicatedThread.start()
                Runtime.live.detached(executorPreference: reading) {
                    await Self.serve(connection, handle: handle)
                    reading.stop()
                }
            }
            unlink(path)
            accepting.stop()
        }
    }

    /// Stops listening and takes the socket away.
    public func stop() {
        listener.withLock { socket in
            socket?.shutDown()
            socket = nil
        }
    }

    /// Answers one connection's lines, one after the other: a peer of another user is closed at once.
    private static func serve(_ connection: UnixSocket, handle: Handler) async {
        guard connection.peerIsSameUser, let pid = connection.peerPID, let peer = ControlPeer.of(pid) else { return }
        while let line = connection.readLine() {
            let reply: ControlReply
            do {
                let request = try ControlLine.decode(ControlRequest.self, from: line)
                reply = await handle(request, peer)
            } catch {
                reply = .failure("not a request: \(error.localizedDescription)")
            }
            guard let data = try? ControlLine.encode(reply), connection.write(data) else { return }
        }
    }
}
