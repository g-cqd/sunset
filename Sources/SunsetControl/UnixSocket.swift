internal import Darwin
import Foundation

/// A Unix domain stream socket: bound and listening for the app, connected for the tool. Only the user who runs the app
/// is answered: the socket's folder is theirs alone (0700), the socket is theirs (0600), and each peer's user is checked.
final class UnixSocket: Sendable {
    enum Failure: Error, CustomStringConvertible {
        case system(String, Int32)
        case pathTooLong(String)

        var description: String {
            switch self {
                case .system(let call, let code): "\(call): \(String(cString: strerror(code)))"
                case .pathTooLong(let path): "the socket's path is too long: \(path)"
            }
        }
    }

    let descriptor: Int32

    init(descriptor: Int32) {
        self.descriptor = descriptor
    }

    deinit {
        close(descriptor)
    }

    /// Listening at `path`: its folder made only the user's, a socket left there by an earlier run taken away.
    static func listening(at path: String) throws(Failure) -> UnixSocket {
        let folder = (path as NSString).deletingLastPathComponent
        do {
            try FileManager.default.createDirectory(
                atPath: folder,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
        } catch {
            throw .system("mkdir \(folder)", EACCES)
        }
        _ = chmod(folder, 0o700)
        unlink(path)
        let socket = try Self.make()
        var address = try Self.address(path)
        let bound = withUnsafePointer(to: &address) {
            unsafe $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                unsafe bind(socket.descriptor, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard bound == 0 else { throw .system("bind", errno) }
        _ = chmod(path, 0o600)
        guard listen(socket.descriptor, 8) == 0 else { throw .system("listen", errno) }
        return socket
    }

    /// Connected to the socket at `path`.
    static func connected(to path: String) throws(Failure) -> UnixSocket {
        let socket = try Self.make()
        var address = try Self.address(path)
        let connected = withUnsafePointer(to: &address) {
            unsafe $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                unsafe connect(socket.descriptor, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard connected == 0 else { throw .system("connect \(path)", errno) }
        return socket
    }

    /// The next connection; nil when the socket was closed.
    func accept() -> UnixSocket? {
        let peer = Darwin.accept(descriptor, nil, nil)
        guard peer >= 0 else { return nil }
        let socket = UnixSocket(descriptor: peer)
        _ = Self.setNoSigPipe(peer)
        return socket
    }

    /// Whether the other end runs as this process's user.
    var peerIsSameUser: Bool {
        var user: uid_t = 0
        var group: gid_t = 0
        guard unsafe getpeereid(descriptor, &user, &group) == 0 else { return false }
        return user == getuid()
    }

    /// Reads up to a newline (not kept); nil at the end, or past `ControlLine.limit`.
    func readLine() -> Data? {
        var line = Data()
        var byte: UInt8 = 0
        while true {
            let count = unsafe Darwin.read(descriptor, &byte, 1)
            guard count == 1 else { return line.isEmpty ? nil : line }
            if byte == 0x0A { return line }
            line.append(byte)
            guard line.count <= ControlLine.limit else { return nil }
        }
    }

    /// Writes all of `data`; false when the other end went away.
    @discardableResult
    func write(_ data: Data) -> Bool {
        data.withUnsafeBytes { raw in
            var offset = 0
            while offset < raw.count {
                let written = unsafe Darwin.write(
                    descriptor,
                    raw.baseAddress.unsafelyUnwrapped + offset,
                    raw.count - offset
                )
                guard written > 0 else { return false }
                offset += written
            }
            return true
        }
    }

    /// Stops `accept` and reads waiting on it.
    func shutDown() {
        Darwin.shutdown(descriptor, SHUT_RDWR)
    }

    private static func make() throws(Failure) -> UnixSocket {
        let descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw .system("socket", errno) }
        _ = setNoSigPipe(descriptor)
        return UnixSocket(descriptor: descriptor)
    }

    private static func setNoSigPipe(_ descriptor: Int32) -> Int32 {
        var on: Int32 = 1
        return unsafe setsockopt(descriptor, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))
    }

    private static func address(_ path: String) throws(Failure) -> sockaddr_un {
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let bytes = Array(path.utf8)
        let capacity = MemoryLayout.size(ofValue: address.sun_path)
        guard bytes.count < capacity else { throw .pathTooLong(path) }
        withUnsafeMutableBytes(of: &address.sun_path) { raw in
            for (index, byte) in bytes.enumerated() { unsafe raw[index] = byte }
        }
        address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        return address
    }
}
