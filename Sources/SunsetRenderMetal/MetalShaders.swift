/// The shaders, as source compiled when the renderer starts (ADR-0006: handwritten, no shader build step). One pipeline draws a frame's list of operations in
/// order, one instance each: a fill sets its pixels, a glyph blends its colour over what is there with the coverage in the atlas. The blend is the CPU
/// renderer's integer formula, `(c * a + d * (255 - a) + 127) / 255` per channel, with the destination read back in the fragment stage (framebuffer fetch,
/// which Apple GPUs have), so the result is bit for bit the CPU's and not a float approximation of it.
enum MetalShaders {
    static let source = """
        #include <metal_stdlib>
        using namespace metal;

        struct Instance {
            int x, y, w, h;
            uint color;
            uint kind;     // 0 fill, 1 glyph
            int sx, sy;    // where the glyph's coverage starts in the atlas
        };

        struct Uniforms {
            float2 size;       // the target in pixels
            uint translucent;  // the destination can have any alpha
        };

        struct Varying {
            float4 position [[position]];
            uint instance [[flat]];
        };

        vertex Varying cell_vertex(uint vertex_id [[vertex_id]], uint instance_id [[instance_id]],
                                   const device Instance *instances [[buffer(0)]], constant Uniforms &uniforms [[buffer(1)]]) {
            Instance item = instances[instance_id];
            float2 corner = float2(vertex_id & 1, vertex_id >> 1);
            float2 pixel = float2(item.x, item.y) + corner * float2(item.w, item.h);
            Varying out;
            out.position = float4(pixel.x / uniforms.size.x * 2.0 - 1.0, 1.0 - pixel.y / uniforms.size.y * 2.0, 0.0, 1.0);
            out.instance = instance_id;
            return out;
        }

        fragment float4 cell_fragment(Varying in [[stage_in]], float4 below [[color(0)]],
                                      const device Instance *instances [[buffer(0)]], constant Uniforms &uniforms [[buffer(1)]],
                                      texture2d<float, access::read> atlas [[texture(0)]]) {
            Instance item = instances[in.instance];
            uint4 c = uint4(item.color & 255u, (item.color >> 8) & 255u, (item.color >> 16) & 255u, item.color >> 24);
            if (item.kind == 0u) {
                return float4(c) / 255.0;
            }
            int2 pixel = int2(in.position.xy);
            uint a = uint(round(atlas.read(uint2(item.sx + (pixel.x - item.x), item.sy + (pixel.y - item.y))).r * 255.0));
            if (a == 0u) {
                return below;
            }
            uint4 d = uint4(round(below * 255.0));
            uint inverse = 255u - a;
            uint3 rgb = (c.rgb * a + d.rgb * inverse + 127u) / 255u;
            uint alpha = uniforms.translucent != 0u ? (255u * a + d.a * inverse + 127u) / 255u : 255u;
            return float4(float3(rgb), float(alpha)) / 255.0;
        }
        """
}
