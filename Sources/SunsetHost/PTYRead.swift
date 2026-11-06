internal import Darwin
internal import Synchronization

public enum PTYRead: Equatable {
    case data(Int)
    case timeout
    /// The child closed its side (it exited) and everything it wrote has been read.
    case closed
}
