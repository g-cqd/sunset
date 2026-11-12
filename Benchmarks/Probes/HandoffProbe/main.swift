// Probe T0.3 (sunset roadmap 0002, ADR-0014): who holds the screen when a renderer wants a frame?
// A reader thread parses a vtebench-like stream (the Swift VT model) in 64 KiB chunks while a renderer thread asks for a consistent copy of the visible
// screen every 8.33 ms (120 Hz). Variants: unfair lock (os_unfair_lock, what Ghostty's mutex is on macOS), fair lock (Alacritty's two-lock scheme),
// demand handoff (Ghostty's), snapshot-on-request (ADR-0014: no lock; the reader publishes the screen between chunks when asked), and "torn" (no sync at all,
// the reader's upper bound, with an inconsistent copy). Probe code: os_unfair_lock and atomics are used directly; none of this is shipping code.
import Foundation
import Synchronization
import VTModel
import os

@inline(__always) func now() -> UInt64 { clock_gettime_nsec_np(CLOCK_UPTIME_RAW) }

final class Shared: @unchecked Sendable {  // probe: every field is either atomic or guarded by the variant's protocol
    let model: Screen
    let lockA = OSAllocatedUnfairLock()
    let lockNext = OSAllocatedUnfairLock()
    let demand = Atomic<Int>(0)
    let handoffGen = Atomic<Int>(0)
    let wanted = Atomic<Int>(0)
    let publishedSeq = Atomic<Int>(0)
    let publishedAt = Atomic<Int>(0)
    let published = Atomic<Int>(0)
    var buffers: [UnsafeMutablePointer<UInt64>] = []
    let stop = Atomic<Bool>(false)
    init() { model = makeScreen(.c8) }
}

final class Out: @unchecked Sendable {
    var bytes = 0
    var maxBlock = 0.0
    var waits: [Double] = []
    var frames = 0
}  // probe: written by one thread each, read after both finish
enum Variant: String, CaseIterable { case none, torn, unfair, fair, demand, snapshot, publish }

struct Result {
    var readerMBs = 0.0
    var frames = 0
    var waits: [Double] = []
    var readerMaxBlockMs = 0.0
}

func percentile(_ xs: [Double], _ p: Double) -> Double {
    xs.isEmpty ? 0 : xs.sorted()[min(xs.count - 1, Int(Double(xs.count - 1) * p))]
}

func run(_ v: Variant, data: [UInt8], seconds: Double) -> Result {
    let sh = Shared()
    let n = 120 * 40
    for _ in 0 ..< 3 {
        let b = UnsafeMutablePointer<UInt64>.allocate(capacity: n)
        b.initialize(repeating: 0, count: n)
        sh.buffers.append(b)
    }
    var result = Result()
    let readerDone = DispatchSemaphore(value: 0)
    let rendererDone = DispatchSemaphore(value: 0)
    let out = Out()
    let deadline = now() + UInt64(seconds * 1e9)
    // reader
    Thread.detachNewThread {
        pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0)
        data.withUnsafeBufferPointer { bp in
            outer: while now() < deadline {
                var o = 0
                while o < bp.count {
                    let e = min(bp.count, o + 65536)
                    let chunk = UnsafeBufferPointer(rebasing: bp[o ..< e])
                    o = e
                    let t0 = now()
                    switch v {
                        case .none, .torn: sh.model.feed(chunk)
                        case .unfair:
                            sh.lockA.lock()
                            let t1 = now()
                            sh.model.feed(chunk)
                            sh.lockA.unlock()
                            out.maxBlock = max(out.maxBlock, Double(t1 - t0) / 1e6)
                        case .fair:
                            sh.lockNext.lock()
                            sh.lockA.lock()
                            sh.lockNext.unlock()
                            let t1 = now()
                            sh.model.feed(chunk)
                            sh.lockA.unlock()
                            out.maxBlock = max(out.maxBlock, Double(t1 - t0) / 1e6)
                        case .demand:
                            // yieldToDemand: before relocking, if a renderer is waiting, let it have its turn (bounded to 1 ms)
                            if sh.demand.load(ordering: .relaxed) > 0 {
                                let g = sh.handoffGen.load(ordering: .acquiring)
                                let limit = now() + 1_000_000
                                while sh.handoffGen.load(ordering: .acquiring) == g && now() < limit { sched_yield() }
                            }
                            sh.lockA.lock()
                            let t1 = now()
                            sh.model.feed(chunk)
                            sh.lockA.unlock()
                            out.maxBlock = max(out.maxBlock, Double(t1 - t0) / 1e6)
                        case .publish:  // always publish after a chunk: the renderer never asks, never waits
                            sh.model.feed(chunk)
                            let t1 = now()
                            let slot = (sh.published.load(ordering: .relaxed) + 1) % 3
                            sh.model.snapshot(into: sh.buffers[slot])
                            sh.publishedAt.store(Int(now()), ordering: .relaxed)
                            sh.published.store(slot, ordering: .releasing)
                            out.maxBlock = max(out.maxBlock, Double(now() - t1) / 1e6)
                        case .snapshot:
                            sh.model.feed(chunk)
                            // publish a copy between chunks; nobody waits on a lock
                            if sh.wanted.load(ordering: .acquiring) == 1 {
                                let t1 = now()
                                let slot = (sh.published.load(ordering: .relaxed) + 1) % 3
                                sh.model.snapshot(into: sh.buffers[slot])
                                sh.published.store(slot, ordering: .releasing)
                                sh.wanted.store(0, ordering: .releasing)
                                sh.publishedSeq.wrappingAdd(1, ordering: .releasing)
                                out.maxBlock = max(out.maxBlock, Double(now() - t1) / 1e6)
                            }
                    }
                    out.bytes += chunk.count
                    if now() >= deadline { break outer }
                }
            }
        }
        readerDone.signal()
    }
    // renderer
    if v != .none {
        Thread.detachNewThread {
            pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0)
            let local = UnsafeMutablePointer<UInt64>.allocate(capacity: n)
            local.initialize(repeating: 0, count: n)
            var next = now() + 8_333_333
            var sink: UInt64 = 0
            while now() < deadline {
                while now() < next { usleep(200) }
                next += 8_333_333
                let t0 = now()
                switch v {
                    case .none: break
                    case .torn:
                        sh.model.snapshot(into: local)
                    case .unfair:
                        sh.lockA.lock()
                        sh.model.snapshot(into: local)
                        sh.lockA.unlock()
                    case .fair:
                        sh.lockNext.lock()
                        sh.lockA.lock()
                        sh.lockNext.unlock()
                        sh.model.snapshot(into: local)
                        sh.lockA.unlock()
                    case .demand:
                        sh.demand.wrappingAdd(1, ordering: .relaxed)
                        sh.lockA.lock()
                        sh.demand.wrappingSubtract(1, ordering: .relaxed)
                        sh.model.snapshot(into: local)
                        sh.lockA.unlock()
                        sh.handoffGen.wrappingAdd(1, ordering: .releasing)
                    case .publish:  // "wait" below is the age of the screen in hand: now - when the reader published it
                        let slot = sh.published.load(ordering: .acquiring)
                        local.update(from: sh.buffers[slot], count: n)
                        let age = Int(now()) - sh.publishedAt.load(ordering: .relaxed)
                        out.waits.append(Double(max(age, 0)) / 1e3)
                        out.frames += 1
                        for i in stride(from: 0, to: n, by: 16) { sink &+= local[i] }
                        continue
                    case .snapshot:
                        let seq = sh.publishedSeq.load(ordering: .acquiring)
                        sh.wanted.store(1, ordering: .releasing)
                        let limit = now() + 200_000_000
                        while sh.publishedSeq.load(ordering: .acquiring) == seq && now() < limit
                            && !sh.stop.load(ordering: .relaxed)
                        { sched_yield() }
                        let slot = sh.published.load(ordering: .acquiring)
                        local.update(from: sh.buffers[slot], count: n)
                }
                out.waits.append(Double(now() - t0) / 1e3)
                for i in stride(from: 0, to: n, by: 16) { sink &+= local[i] }  // consume the frame
                out.frames += 1
            }
            if sink == 42 { print() }
            rendererDone.signal()
        }
    } else {
        rendererDone.signal()
    }
    readerDone.wait()
    sh.stop.store(true, ordering: .relaxed)
    rendererDone.wait()
    result.readerMBs = Double(out.bytes) / seconds / 1e6
    result.frames = out.frames
    result.waits = out.waits
    result.readerMaxBlockMs = out.maxBlock
    return result
}

let streams: [(String, [UInt8])] = [
    ("dense_cells", Streams.denseCells), ("scrolling", Streams.scrolling), ("log", Streams.log)
]
let secs = Double(ProcessInfo.processInfo.environment["SECS"] ?? "3") ?? 3
print(
    "T0.3 handoff probe, \(secs) s per cell, load \(ProcessInfo.processInfo.environment["LOAD"] ?? "ambient"); renderer asks for a frame every 8.33 ms; wait = request -> consistent copy in hand (µs)"
)
print(
    String(
        format: "%-12@ %-9@ %10@ %7@ %9@ %9@ %9@ %10@ %12@",
        "stream" as NSString,
        "variant" as NSString,
        "reader MB/s" as NSString,
        "frames" as NSString,
        "wait p50" as NSString,
        "wait p99" as NSString,
        "wait max" as NSString,
        "rdr blk max" as NSString,
        "(ms)" as NSString
    )
)
for (name, data) in streams {
    for v in Variant.allCases {
        let r = run(v, data: data, seconds: secs)
        print(
            String(
                format: "%-12@ %-9@ %10.1f %7d %9.0f %9.0f %9.0f %10.2f",
                name as NSString,
                v.rawValue as NSString,
                r.readerMBs,
                r.frames,
                percentile(r.waits, 0.5),
                percentile(r.waits, 0.99),
                r.waits.max() ?? 0,
                r.readerMaxBlockMs
            )
        )
    }
}
