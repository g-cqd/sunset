import Testing

@testable import SunsetCore

struct Recorder: VTSink {
    var events: [Event] = []

    mutating func printASCII(_ run: Span<UInt8>) {
        for index in run.indices { events.append(.text(Unicode.Scalar(run[index]))) }
    }
    mutating func print(_ scalar: Unicode.Scalar) { events.append(.text(scalar)) }
    mutating func execute(_ control: UInt8) { events.append(.execute(control)) }
    mutating func escape(_ intermediates: Intermediates, final: UInt8) {
        events.append(.escape(final, bytes(intermediates)))
    }
    mutating func csi(_ parameters: Parameters, marker: UInt8, intermediates: Intermediates, final: UInt8) {
        events.append(
            .csi(
                marker: marker,
                parameters: list(parameters),
                subMask: parameters.subParameterMask,
                intermediates: bytes(intermediates),
                final: final
            )
        )
    }
    mutating func stringStart(
        _ kind: StringKind,
        parameters: Parameters,
        marker: UInt8,
        intermediates: Intermediates,
        final: UInt8
    ) {
        events.append(
            .stringStart(
                kind,
                header: list(parameters),
                marker: marker,
                intermediates: bytes(intermediates),
                final: final
            )
        )
    }
    mutating func stringBytes(_ bytes: Span<UInt8>) {
        var piece: [UInt8] = []
        for index in bytes.indices { piece.append(bytes[index]) }
        // Pieces of one string are merged: how the input was cut must not show.
        if case .stringBytes(let before)? = events.last {
            events[events.count - 1] = .stringBytes(before + piece)
        } else {
            events.append(.stringBytes(piece))
        }
    }
    var endings: [StringTerminator] = []
    mutating func stringEnd(completed: Bool, terminator: StringTerminator) {
        events.append(.stringEnd(completed: completed))
        endings.append(terminator)
    }

    private func list(_ parameters: Parameters) -> [Int] { (0 ..< parameters.count).map { parameters[$0] } }
    private func bytes(_ intermediates: Intermediates) -> [UInt8] {
        [intermediates.first, intermediates.second].prefix(intermediates.count).map { $0 }
    }
}
