public enum PTYError: Error, Equatable {
    case openFailed(errno: Int32)
    case spawnFailed(errno: Int32)
    case writeFailed(errno: Int32)
}
