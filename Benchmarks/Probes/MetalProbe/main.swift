// Probe T0.5 (sunset roadmap 0002, ADR-0015): does the GPU reading the screen's own 8-byte cells beat rebuilding instance data on the CPU every frame?
// Offscreen Metal render of a terminal grid (cell 9x18 px). Variants:
//   A-full : CPU rebuilds one 32-byte instance per cell (Ghostty-style `rebuildCells`) every frame, copies it to a shared MTLBuffer, draws instanced quads.
//   A-dirty: same, but rebuilds only the one row that changed this frame (what a partial update costs when row dirty flags work).
//   B      : the cell array itself is the MTLBuffer (page-aligned memory wrapped with bytesNoCopy); the vertex shader decodes cells; the CPU writes one row/frame.
// Measured per frame: CPU prepare (A: build+copy; B: the row write), CPU encode+commit, GPU time (gpuStartTime..gpuEndTime), submit-to-complete wall time.
// Probe code: it renders random ASCII from a random atlas; nothing here is visually checked, only timed. Machine load is whatever it is (ADR-0017).
import Foundation
import Metal

let msl = """
    #include <metal_stdlib>
    using namespace metal;
    struct Inst { uint4 glyph; uint fg; uint bg; ushort col; ushort row; uint pad; };   // 32 bytes
    struct Out { float4 pos [[position]]; float2 uv; float4 fg; float4 bg; };
    struct Params { uint cols; uint rows; float2 cellPx; float2 targetPx; float2 atlasPx; };
    float4 unpack(uint c) { return float4(float(c & 255), float((c >> 8) & 255), float((c >> 16) & 255), 255.0) / 255.0; }
    float2 corner(uint vid) { const float2 q[6] = { {0,0},{1,0},{0,1},{1,0},{1,1},{0,1} }; return q[vid]; }
    vertex Out vsA(uint vid [[vertex_id]], uint iid [[instance_id]], constant Inst *inst [[buffer(0)]], constant Params &p [[buffer(1)]]) {
        Inst i = inst[iid]; float2 q = corner(vid); Out o;
        float2 px = (float2(i.col, i.row) + q) * p.cellPx; o.pos = float4(px / p.targetPx * float2(2, -2) + float2(-1, 1), 0, 1);
        o.uv = (float2(i.glyph.xy) + q * float2(i.glyph.zw)) / p.atlasPx; o.fg = unpack(i.fg); o.bg = unpack(i.bg); return o;
    }
    vertex Out vsB(uint vid [[vertex_id]], uint iid [[instance_id]], constant ulong *cells [[buffer(0)]], constant Params &p [[buffer(1)]],
                   constant uint4 *glyphs [[buffer(2)]], constant uint2 *styles [[buffer(3)]]) {
        ulong c = cells[iid]; uint cp = uint(c & 0x1FFFFF), st = uint((c >> 24) & 0xFFFF);
        uint col = iid % p.cols, row = iid / p.cols; float2 q = corner(vid); Out o;
        float2 px = (float2(col, row) + q) * p.cellPx; o.pos = float4(px / p.targetPx * float2(2, -2) + float2(-1, 1), 0, 1);
        uint4 g = glyphs[cp & 127]; o.uv = (float2(g.xy) + q * float2(g.zw)) / p.atlasPx; uint2 s = styles[st & 255]; o.fg = unpack(s.x); o.bg = unpack(s.y); return o;
    }
    fragment float4 fs(Out in [[stage_in]], texture2d<float> atlas [[texture(0)]]) {
        constexpr sampler s(filter::nearest); float a = atlas.sample(s, in.uv).r; return mix(in.bg, in.fg, a);
    }
    """

// swift-format-ignore: NeverForceUnwrap
let device = MTLCreateSystemDefaultDevice()!
// swift-format-ignore: NeverForceUnwrap
let queue = device.makeCommandQueue()!
// swift-format-ignore: NeverUseForceTry
let lib = try! device.makeLibrary(source: msl, options: nil)
func pipeline(_ v: String) -> MTLRenderPipelineState {
    let d = MTLRenderPipelineDescriptor()
    d.vertexFunction = lib.makeFunction(name: v)
    d.fragmentFunction = lib.makeFunction(name: "fs")
    d.colorAttachments[0].pixelFormat = .bgra8Unorm
    // swift-format-ignore: NeverUseForceTry
    return try! device.makeRenderPipelineState(descriptor: d)
}
let psoA = pipeline("vsA")
let psoB = pipeline("vsB")

struct Inst {
    var glyph: SIMD4<UInt32>
    var fg: UInt32
    var bg: UInt32
    var col: UInt16
    var row: UInt16
    var pad: UInt32
}
struct Params {
    var cols: UInt32
    var rows: UInt32
    var cellPx: SIMD2<Float>
    var targetPx: SIMD2<Float>
    var atlasPx: SIMD2<Float>
}
precondition(MemoryLayout<Inst>.stride == 32)

func now() -> UInt64 { clock_gettime_nsec_np(CLOCK_UPTIME_RAW) }
func pct(_ xs: [Double], _ p: Double) -> Double {
    xs.isEmpty ? 0 : xs.sorted()[min(xs.count - 1, Int(Double(xs.count - 1) * p))]
}

func runSize(cols: Int, rows: Int, frames: Int) {
    let n = cols * rows
    let cellW = 9
    let cellH = 18
    let tw = cols * cellW
    let th = rows * cellH
    let td = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: tw, height: th, mipmapped: false)
    td.usage = .renderTarget
    td.storageMode = .private
    // swift-format-ignore: NeverForceUnwrap
    let target = device.makeTexture(descriptor: td)!
    let ad = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .r8Unorm,
        width: 1024,
        height: 1024,
        mipmapped: false
    )
    // swift-format-ignore: NeverForceUnwrap
    let atlas = device.makeTexture(descriptor: ad)!
    var noise = [UInt8](repeating: 0, count: 1024 * 1024)
    var x: UInt64 = 88_172_645_463_325_252
    for i in 0 ..< noise.count {
        x ^= x << 13
        x ^= x >> 7
        x ^= x << 17
        noise[i] = UInt8(truncatingIfNeeded: x)
    }
    atlas.replace(region: MTLRegionMake2D(0, 0, 1024, 1024), mipmapLevel: 0, withBytes: noise, bytesPerRow: 1024)
    var glyphTable: [SIMD4<UInt32>] = []
    for g in 0 ..< 128 { glyphTable.append(SIMD4(UInt32((g % 64) * 16), UInt32((g / 64) * 32 + 64), 9, 18)) }
    var styleTable: [SIMD2<UInt32>] = []
    for s in 0 ..< 256 {
        styleTable.append(
            SIMD2(UInt32(0xFF_00_00_00 | (s &* 2_654_435_761) & 0xFFFFFF) | 0x808080, UInt32((s &* 40503) & 0x3F3F3F))
        )
    }
    // swift-format-ignore: NeverForceUnwrap
    let glyphBuf = device.makeBuffer(bytes: glyphTable, length: 128 * 16, options: .storageModeShared)!
    // swift-format-ignore: NeverForceUnwrap
    let styleBuf = device.makeBuffer(bytes: styleTable, length: 256 * 8, options: .storageModeShared)!
    var params = Params(
        cols: UInt32(cols),
        rows: UInt32(rows),
        cellPx: SIMD2(Float(cellW), Float(cellH)),
        targetPx: SIMD2(Float(tw), Float(th)),
        atlasPx: SIMD2(1024, 1024)
    )

    // the screen: page-aligned 8-byte cells wrapped as a Metal buffer (variant B) and read by the CPU rebuild (variant A)
    let page = Int(getpagesize())
    let bytes = (n * 8 + page - 1) / page * page
    var raw: UnsafeMutableRawPointer? = nil
    posix_memalign(&raw, page, bytes)
    // swift-format-ignore: NeverForceUnwrap
    let cells = raw!.bindMemory(to: UInt64.self, capacity: bytes / 8)
    var r: UInt64 = 7
    func rnd() -> UInt64 {
        r = r &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return r >> 33
    }
    for i in 0 ..< n { cells[i] = UInt64(0x20 + rnd() % 95) | UInt64(rnd() % 256) << 24 }
    // swift-format-ignore: NeverForceUnwrap
    let cellBuf = device.makeBuffer(bytesNoCopy: raw!, length: bytes, options: .storageModeShared, deallocator: nil)!
    // swift-format-ignore: NeverForceUnwrap
    let instBufs = (0 ..< 3).map { _ in device.makeBuffer(length: n * 32, options: .storageModeShared)! }
    let inst = UnsafeMutablePointer<Inst>.allocate(capacity: n)

    // CPU: decode cells -> 32-byte instances (what Ghostty's rebuildCells does per dirty row)
    func rebuild(rows r0: Range<Int>) {
        for row in r0 {
            for col in 0 ..< cols {
                let i = row * cols + col
                let c = cells[i]
                let cp = Int(c & 0x7F)
                let st = Int((c >> 24) & 0xFF)
                inst[i] = Inst(
                    glyph: glyphTable[cp],
                    fg: styleTable[st].x,
                    bg: styleTable[st].y,
                    col: UInt16(col),
                    row: UInt16(row),
                    pad: 0
                )
            }
        }
    }
    print(
        "\n== \(cols)x\(rows) cells, target \(tw)x\(th), \(frames) frames (after 60 warm-up), per-frame times in µs: p50 / p99"
    )
    print(
        String(
            format: "%-9@ %16@ %16@ %16@ %16@",
            "variant" as NSString,
            "cpu prepare" as NSString,
            "cpu encode+commit" as NSString,
            "gpu time" as NSString,
            "submit->done" as NSString
        )
    )
    for variant in ["A-full", "A-dirty", "B"] {
        var prep: [Double] = []
        var enc: [Double] = []
        var gpu: [Double] = []
        var wall: [Double] = []
        rebuild(rows: 0 ..< rows)
        // initial state for A-dirty
        for b in 0 ..< 3 { instBufs[b].contents().copyMemory(from: inst, byteCount: n * 32) }
        for f in 0 ..< (frames + 60) {
            let changeRow = f % rows
            // the "parser" changed one row
            for c in 0 ..< cols { cells[changeRow * cols + c] = UInt64(0x20 + rnd() % 95) | UInt64(rnd() % 256) << 24 }
            let t0 = now()
            if variant == "A-full" {
                rebuild(rows: 0 ..< rows)
            } else if variant == "A-dirty" {
                rebuild(rows: changeRow ..< (changeRow + 1))
            }
            if variant == "A-full" {
                instBufs[f % 3].contents().copyMemory(from: inst, byteCount: n * 32)
            }  // upload (shared memory: a copy)
            else if variant == "A-dirty" {  // partial upload: the changed row, plus the two other
                // ring buffers must also hold the previous rows' instances, so they are brought up to date row by row (3 buffers, 1 row/frame: copy the row into all three)
                for b in 0 ..< 3 {
                    (instBufs[b].contents() + changeRow * cols * 32)
                        .copyMemory(from: inst + changeRow * cols, byteCount: cols * 32)
                }
            }
            let t1 = now()
            let rp = MTLRenderPassDescriptor()
            rp.colorAttachments[0].texture = target
            rp.colorAttachments[0].loadAction = .clear
            rp.colorAttachments[0].storeAction = .store
            // swift-format-ignore: NeverForceUnwrap
            let cb = queue.makeCommandBuffer()!
            // swift-format-ignore: NeverForceUnwrap
            let enc_ = cb.makeRenderCommandEncoder(descriptor: rp)!
            if variant == "B" {
                enc_.setRenderPipelineState(psoB)
                enc_.setVertexBuffer(cellBuf, offset: 0, index: 0)
                enc_.setVertexBytes(&params, length: MemoryLayout<Params>.size, index: 1)
                enc_.setVertexBuffer(glyphBuf, offset: 0, index: 2)
                enc_.setVertexBuffer(styleBuf, offset: 0, index: 3)
            } else {
                enc_.setRenderPipelineState(psoA)
                enc_.setVertexBuffer(instBufs[f % 3], offset: 0, index: 0)
                enc_.setVertexBytes(&params, length: MemoryLayout<Params>.size, index: 1)
            }
            enc_.setFragmentTexture(atlas, index: 0)
            enc_.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6, instanceCount: n)
            enc_.endEncoding()
            cb.commit()
            let t2 = now()
            cb.waitUntilCompleted()
            let t3 = now()
            if f >= 60 {
                prep.append(Double(t1 - t0) / 1e3)
                enc.append(Double(t2 - t1) / 1e3)
                gpu.append((cb.gpuEndTime - cb.gpuStartTime) * 1e6)
                wall.append(Double(t3 - t1) / 1e3)
            }
        }
        print(
            String(
                format: "%-9@ %7.1f / %-7.1f %7.1f / %-7.1f %7.1f / %-7.1f %7.1f / %-7.1f",
                variant as NSString,
                pct(prep, 0.5),
                pct(prep, 0.99),
                pct(enc, 0.5),
                pct(enc, 0.99),
                pct(gpu, 0.5),
                pct(gpu, 0.99),
                pct(wall, 0.5),
                pct(wall, 0.99)
            )
        )
    }
    inst.deallocate()
    free(raw)
}
print(
    "T0.5 Metal direct-read probe on \(device.name); load \(ProcessInfo.processInfo.environment["LOAD"] ?? "ambient")"
)
runSize(cols: 120, rows: 40, frames: 600)
runSize(cols: 300, rows: 80, frames: 600)
