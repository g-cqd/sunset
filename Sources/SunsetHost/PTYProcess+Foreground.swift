internal import Darwin

extension PTYProcess {
    /// The name of the program that has the terminal in front (the foreground process group), or nil when it is the child itself (the shell, at its prompt), when
    /// the child is gone, or when the name cannot be read. The group leader is named, which is the program a shell started (a pipeline is named by its first
    /// command); an interpreter's script shows as the interpreter.
    public func foregroundCommandName() -> String? {
        let front = tcgetpgrp(master)
        guard front > 0, case let own = getpgid(processID), own > 0, front != own else { return nil }
        var buffer = [CChar](repeating: 0, count: 64)
        let length = buffer.withUnsafeMutableBufferPointer {
            unsafe proc_name(front, $0.baseAddress, UInt32($0.count))
        }
        guard length > 0 else { return nil }
        return String(decoding: buffer.prefix(Int(length)).map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }
}
