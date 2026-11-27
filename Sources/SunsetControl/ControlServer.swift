internal import Darwin
import Foundation
import Synchronization

/// The app's end of the control socket: each connection sends request lines and is answered, line for line, by
/// `handle`, told who asks (`ControlPeer`). Off unless the app starts it (`control.enabled`).
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
        Thread.detachNewThread {
            while let connection = socket.accept() {
                Thread.detachNewThread { Self.serve(connection, handle: handle) }
            }
            unlink(path)
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
    private static func serve(_ connection: UnixSocket, handle: @escaping Handler) {
        guard connection.peerIsSameUser, let pid = connection.peerPID, let peer = ControlPeer.of(pid) else { return }
        while let line = connection.readLine() {
            let reply: ControlReply
            do {
                let request = try ControlLine.decode(ControlRequest.self, from: line)
                reply = Self.answer(request, from: peer, handle: handle)
            } catch {
                reply = .failure("not a request: \(error.localizedDescription)")
            }
            guard let data = try? ControlLine.encode(reply), connection.write(data) else { return }
        }
    }

    /// `handle`'s reply, waited for on this connection's own thread.
    private static func answer(_ request: ControlRequest, from peer: ControlPeer, handle: @escaping Handler)
        -> ControlReply
    {
        let done = DispatchSemaphore(value: 0)
        let reply = Mutex<ControlReply?>(nil)
        Task {
            let answer = await handle(request, peer)
            reply.withLock { $0 = answer }
            done.signal()
        }
        done.wait()
        return reply.withLock { $0 } ?? .failure("no answer")
    }
}
