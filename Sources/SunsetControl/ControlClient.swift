/// The tool's end of the control socket: one request, its reply.
public enum ControlClient {
    public enum Failure: Error, CustomStringConvertible {
        case notRunning(String)
        case noReply

        public var description: String {
            switch self {
                case .notRunning(let why):
                    "Sunset is not answering (\(why)): is it open, with Settings › General › Control from outside on?"
                case .noReply: "Sunset closed the connection without a reply"
            }
        }
    }

    public static func send(_ request: ControlRequest, path: String = ControlPath.standard) throws -> ControlReply {
        let socket: UnixSocket
        do {
            socket = try UnixSocket.connected(to: path)
        } catch {
            throw Failure.notRunning(error.description)
        }
        guard socket.write(try ControlLine.encode(request)), let line = socket.readLine() else { throw Failure.noReply }
        return try ControlLine.decode(ControlReply.self, from: line)
    }
}
