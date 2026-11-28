// Draws Sunset's icon masters (roadmap 0084, ADR-0084): the skies, each as it is and tinted (no darker one for dark
// mode: the sun is as it is whatever the system's appearance, the owner 2026-11-28), with the shader in
// Sky.metal beside this file.
//   swift Design/Icons/RenderIcon.swift <output folder>      then python3 Design/Icons/build_icons.py
// The owner's choices, 2026-11-19: candidate F (the sun half hidden, soft haze; no disc, no line, no clouds), Twilight bluer
// and pinker, Dawn the palest (halfway between two looks: `dawnMix` in Sky.metal), Dusk burnt and darker.
// Proposed 2026-11-28, hidden behind Option in the picker until approved: Sunrise, Later morning, Noon, Afternoon (`day`,
// `gold`: the same sun a little higher, a clearer sky) and Night (`night`: the moon, a few stars).
import CoreGraphics
import Foundation
import ImageIO
import Metal
import UniformTypeIdentifiers

/// What the shader reads, in its order (`IconUniforms` in Sky.metal).
struct IconUniforms {
    var resolution: SIMD2<Float>
    var sunElevationDeg: Float
    var exposure: Float
    var turbidity: Float = 2.35
    var ozoneStrength: Float = 2.8
    var chromaticStrength: Float = 1.0
    var grainStrength: Float = 0.0045
    // Candidate F: the sun's centre half its radius under the horizon, its glow 0.13 of the icon, a soft haze.
    var sunDrop: Float = 0.50
    var coreSize: Float = 0.13
    var curve: Float = 0.08
    var mistSoft: Float = 0.06
    var pale: Float = 0
    var burn: Float = 0
    var airy: Float = 0
    var day: Float = 0
    var gold: Float = 0
    var night: Float = 0
    var layerMode: Int32
}

/// One master: its file name, and how the shader draws it (layer mode 0 the sky, 3 tinted).
struct Master {
    let name: String
    let mode: Int32
    let elevation: Float
    let exposure: Float
    var pale: Float = 0
    var burn: Float = 0
    var airy: Float = 0
    var day: Float = 0
    var gold: Float = 0
    var night: Float = 0
    var sunDrop: Float = 0.5
    var core: Float = 0.13
    var turbidity: Float = 2.35
}

/// The proposed skies (2026-11-28), as they are and tinted.
let proposed: [Master] = [
    Master(name: "sunrise", mode: 0, elevation: 3.0, exposure: 0.86, day: 0.3, gold: 1, sunDrop: 0.2, turbidity: 2.2),
    Master(
        name: "sunrise-tinted",
        mode: 3,
        elevation: 3.0,
        exposure: 0.86,
        day: 0.3,
        gold: 1,
        sunDrop: 0.2,
        turbidity: 2.2
    ),
    Master(
        name: "morning",
        mode: 0,
        elevation: 10,
        exposure: 0.66,
        day: 0.75,
        sunDrop: -0.6,
        core: 0.12,
        turbidity: 1.9
    ),
    Master(
        name: "morning-tinted",
        mode: 3,
        elevation: 10,
        exposure: 0.66,
        day: 0.75,
        sunDrop: -0.6,
        core: 0.12,
        turbidity: 1.9
    ),
    Master(name: "noon", mode: 0, elevation: 30, exposure: 0.56, day: 1, sunDrop: -1.4, core: 0.115, turbidity: 1.7),
    Master(
        name: "noon-tinted",
        mode: 3,
        elevation: 30,
        exposure: 0.56,
        day: 1,
        sunDrop: -1.4,
        core: 0.115,
        turbidity: 1.7
    ),
    Master(
        name: "afternoon",
        mode: 0,
        elevation: 14,
        exposure: 0.64,
        day: 0.75,
        gold: 1,
        sunDrop: -0.9,
        core: 0.12,
        turbidity: 2.1
    ),
    Master(
        name: "afternoon-tinted",
        mode: 3,
        elevation: 14,
        exposure: 0.64,
        day: 0.75,
        gold: 1,
        sunDrop: -0.9,
        core: 0.12,
        turbidity: 2.1
    ),
    Master(name: "night", mode: 0, elevation: -6.0, exposure: 0.85, night: 1),
    Master(name: "night-tinted", mode: 3, elevation: -6.0, exposure: 0.85, night: 1)
]

let masters: [Master] =
    [
        Master(name: "sunset", mode: 0, elevation: -0.4, exposure: 0.92),
        Master(name: "sunset-tinted", mode: 3, elevation: -0.4, exposure: 0.92),
        Master(name: "twilight", mode: 0, elevation: 0.2, exposure: 0.80, pale: 1),
        Master(name: "twilight-tinted", mode: 3, elevation: 0.2, exposure: 0.80, pale: 1),
        Master(name: "dawn", mode: 0, elevation: 0.6, exposure: 0.85, pale: 1, airy: 1),
        Master(name: "dawn-tinted", mode: 3, elevation: 0.6, exposure: 0.85, pale: 1, airy: 1),
        Master(name: "dusk", mode: 0, elevation: -3.0, exposure: 0.95, burn: 1),
        Master(name: "dusk-tinted", mode: 3, elevation: -3.0, exposure: 0.95, burn: 1)
    ] + proposed

enum RenderError: Error {
    case noMetal, noPipeline
    case noImage(String)
}

/// The shader's pipeline, ready to draw.
struct Renderer {
    let device: MTLDevice
    let queue: MTLCommandQueue
    let pipeline: MTLRenderPipelineState

    init(shader: URL) throws {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else {
            throw RenderError.noMetal
        }
        let library = try device.makeLibrary(
            source: String(contentsOf: shader, encoding: .utf8),
            options: MTLCompileOptions()
        )
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "icon_vertex")
        descriptor.fragmentFunction = library.makeFunction(name: "icon_fragment")
        descriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
        self.device = device
        self.queue = queue
        self.pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    /// Draws `master` at `size` pixels square and writes it as a PNG at `path`.
    func render(_ master: Master, size: Int, to path: String) throws {
        let texture = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: size,
            height: size,
            mipmapped: false
        )
        texture.storageMode = .shared
        texture.usage = [.renderTarget]
        let pass = MTLRenderPassDescriptor()
        guard let target = device.makeTexture(descriptor: texture), let commands = queue.makeCommandBuffer() else {
            throw RenderError.noPipeline
        }
        pass.colorAttachments[0].texture = target
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        pass.colorAttachments[0].storeAction = .store
        guard let encoder = commands.makeRenderCommandEncoder(descriptor: pass) else { throw RenderError.noPipeline }
        var uniforms = IconUniforms(
            resolution: SIMD2(Float(size), Float(size)),
            sunElevationDeg: master.elevation,
            exposure: master.exposure,
            turbidity: master.turbidity,
            sunDrop: master.sunDrop,
            coreSize: master.core,
            pale: master.pale,
            burn: master.burn,
            airy: master.airy,
            day: master.day,
            gold: master.gold,
            night: master.night,
            layerMode: master.mode
        )
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<IconUniforms>.size, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        commands.commit()
        commands.waitUntilCompleted()

        var bytes = [UInt8](repeating: 0, count: size * size * 4)
        target.getBytes(&bytes, bytesPerRow: size * 4, from: MTLRegionMake2D(0, 0, size, size), mipmapLevel: 0)
        try write(bytes, size: size, to: path)
    }

    private func write(_ bytes: [UInt8], size: Int, to path: String) throws {
        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
            let provider = CGDataProvider(data: Data(bytes) as CFData),
            let image = CGImage(
                width: size,
                height: size,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: size * 4,
                space: space,
                bitmapInfo: info,
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
            ),
            let file = CGImageDestinationCreateWithURL(
                URL(fileURLWithPath: path) as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            )
        else { throw RenderError.noImage(path) }
        CGImageDestinationAddImage(file, image, nil)
        guard CGImageDestinationFinalize(file) else { throw RenderError.noImage(path) }
    }
}

let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".build/icons/masters"
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
let shader = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appending(path: "Sky.metal")
let renderer = try Renderer(shader: shader)
for master in masters {
    try renderer.render(master, size: 1024, to: "\(output)/\(master.name).png")
}
print("ok")
