// Sunset's sky, alive, for the welcome (roadmap 0111 H, 0084 G): the icon's sky (Design/Icons/Sky.metal) made light
// enough for a whole screen at the display's rate: one sample a pixel (no chromatic split), 12 steps along the view and
// 4 towards the sun (the icon takes 20 and 8). Drawn into an extended-range layer (`SunsetSkyLayer`): the sky tone-mapped
// to the display's white, the sun's heart above it by the display's headroom (the owner, 2026-11-21: "exploit hdr values
// for the sun"); on a display without headroom it is the icon's look. The sun and the sky are separate layers (the owner,
// 2026-11-21: "separate the sun and the sky in the shader and animation to animate them in different phases"): the
// opening draws the sun alone over the screen; the window draws both. Nothing here stands in for the window's shape.
#include <metal_stdlib>
using namespace metal;

static inline float skyHash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031f);
    p3 += dot(p3, p3.yzx + 33.33f);
    return fract((p3.x + p3.y) * p3.z);
}

static inline float skyNoise(float2 p) {
    float2 i = floor(p), f = fract(p), w = f * f * (3.0f - 2.0f * f);
    return mix(mix(skyHash(i), skyHash(i + float2(1, 0)), w.x), mix(skyHash(i + float2(0, 1)), skyHash(i + float2(1, 1)), w.x), w.y);
}

static float3 skyAtmosphere(float3 dir, float sunElevRad) {
    const float turbidity = 2.35f, ozoneStrength = 2.8f;
    float3 sunDir = normalize(float3(0.0f, sin(sunElevRad), cos(sunElevRad)));
    const float Re = 6371.0f, Ra = 6471.0f, Hr = 8.0f, Hm = 1.35f;
    const float3 betaR = float3(0.005802f, 0.013558f, 0.033100f);
    const float3 betaMScat = float3(0.003996f) * turbidity;
    const float3 betaMExt = float3(0.004440f) * turbidity;
    const float3 betaO = float3(0.000650f, 0.001881f, 0.000085f) * ozoneStrength;

    float smoothY = 0.5f * (dir.y + sqrt(dir.y * dir.y + 0.0045f)) + 0.003f;
    float3 rDir = normalize(float3(dir.x, smoothY, dir.z));
    float3 origin = float3(0.0f, Re + 0.22f, 0.0f);
    float b = dot(origin, rDir);
    float c = dot(origin, origin) - Ra * Ra;
    float tMax = -b + sqrt(max(b * b - c, 0.0f));

    float cosTheta = dot(rDir, sunDir);
    float phaseR = 3.0f / (16.0f * 3.14159265f) * (1.0f + cosTheta * cosTheta);
    float g = 0.78f, g2 = g * g;
    float phaseM = 3.0f / (8.0f * 3.14159265f) * ((1.0f - g2) * (1.0f + cosTheta * cosTheta))
        / ((2.0f + g2) * pow(max(1.0f + g2 - 2.0f * g * cosTheta, 0.001f), 1.5f));

    float optR = 0.0f, optM = 0.0f, optO = 0.0f;
    float3 sumR = float3(0.0f), sumM = float3(0.0f), sumMulti = float3(0.0f);
    const int steps = 12, sunSteps = 4;
    for (int i = 0; i < steps; i++) {
        float u0 = float(i) / float(steps), u1 = float(i + 1) / float(steps);
        float t0 = tMax * u0 * u0, t1 = tMax * u1 * u1;
        float segDt = t1 - t0;
        float3 pos = origin + rDir * (0.5f * (t0 + t1));
        float h = max(length(pos) - Re, 0.0f);
        float dR = exp(-h / Hr) * segDt;
        float dM = exp(-h / Hm) * segDt;
        float dO = max(0.0f, 1.0f - abs(h - 25.0f) / 15.0f) * segDt;
        optR += dR; optM += dM; optO += dO;

        float r = length(pos);
        float mu = dot(pos / r, sunDir);
        float minAlt = (mu < 0.0f) ? (r * sqrt(max(1.0f - mu * mu, 0.0f)) - Re) : (r - Re);
        float shadow = smoothstep(-16.0f, 24.0f, minAlt);

        float ba = dot(pos, sunDir), ca = dot(pos, pos) - Ra * Ra;
        float tSunMax = -ba + sqrt(max(ba * ba - ca, 0.0f));
        float dtSun = tSunMax / float(sunSteps);
        float sR = 0, sM = 0, sO = 0;
        for (int j = 0; j < sunSteps; j++) {
            float3 sPos = pos + sunDir * ((float(j) + 0.5f) * dtSun);
            float sh = max(length(sPos) - Re, 0.0f);
            sR += exp(-sh / Hr) * dtSun;
            sM += exp(-sh / Hm) * dtSun;
            sO += max(0.0f, 1.0f - abs(sh - 25.0f) / 15.0f) * dtSun;
        }
        float3 tauSun = betaR * sR + betaMExt * sM + betaO * sO;
        float3 tauView = betaR * optR + betaMExt * optM + betaO * optO;
        float3 atten = exp(-(tauView + tauSun));
        sumR += atten * shadow * dR;
        sumM += atten * shadow * dM;
        sumMulti += exp(-tauView) * float3(0.10f, 0.16f, 0.58f) * (0.35f + 0.65f * shadow) * (betaR * dR * 0.075f);
    }
    float3 sky = float3(21.0f, 18.2f, 16.0f) * (sumR * betaR * phaseR + sumM * betaMScat * phaseM + sumMulti);
    float twilight = clamp(1.0f - abs(sunElevRad + 0.018f) / 0.16f, 0.0f, 1.0f);
    sky += float3(0.68f, 0.16f, 0.38f) * twilight * exp(-pow((rDir.y - 0.14f) / 0.12f, 2.0f)) * 0.24f;
    sky += float3(1.15f, 0.32f, 0.10f) * twilight * exp(-pow(rDir.y / 0.085f, 2.0f)) * 0.32f;
    return sky;
}

struct SkyUniforms {
    float2 frameOrigin;  // the sky's frame (the window's), in points from the layer's top left
    float2 frameSize;
    float2 sun;          // where the sky keeps the sun
    float skyOpacity;    // 0: the sun alone
    float sunOpacity;
    float sunDefocus;    // 1: a wide blur; 0: sharp
    float elevation;
    float horizon;
    float time;
    float headroom;      // the display's: 1 without HDR
    float scale;         // pixels a point
    float2 sunAspect;    // distances from its middle scaled by this: (1, 1) round; the window's a little wider
};

struct SkyVertex { float4 position [[position]]; };

vertex SkyVertex sky_vertex(uint vid [[vertex_id]]) {
    float2 corners[3] = { float2(-1, -1), float2(3, -1), float2(-1, 3) };
    SkyVertex out;
    out.position = float4(corners[vid], 0, 1);
    return out;
}

/// Where a point of the window's frame looks, and its height under the horizon.
struct SkyRay { float3 dir; float dx; float dy; };

static SkyRay skyRay(float2 uv, float aspect, constant SkyUniforms &u) {
    float band = exp(-pow((uv.y - u.horizon) / 0.16f, 2.0f));
    float2 w = float2(skyNoise(float2(uv.x * 7.0f, uv.y * 22.0f) + u.time * 0.35f),
                      skyNoise(float2(uv.x * 9.0f + 5.7f, uv.y * 18.0f) - u.time * 0.27f)) - 0.5f;
    uv += w * float2(0.0030f, 0.0050f) * band;
    SkyRay ray;
    ray.dx = (uv.x - 0.5f) * aspect;
    ray.dy = uv.y - (u.horizon + ray.dx * ray.dx * 0.08f / max(aspect, 1.0f));
    float pitch = max(-ray.dy, 0.0f) * 0.78f;
    float yaw = ray.dx * 1.04f;
    ray.dir = normalize(float3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)));
    return ray;
}

/// The sky alone, in linear light: the air, the haze band, the dark below. No sun in it.
static float3 skyLayer(SkyRay ray, constant SkyUniforms &u) {
    const float mistSoft = 0.06f;
    float3 s = skyAtmosphere(ray.dir, u.elevation * (3.14159265f / 180.0f)) * 0.54f;
    s += float3(0.95f, 0.42f, 0.26f) * exp(-pow((ray.dy + mistSoft * 0.3f) / (mistSoft * 2.4f), 2.0f)) * 0.30f;
    float fall = smoothstep(-mistSoft * 0.5f, mistSoft * 7.0f, ray.dy);
    s *= mix(1.0f, mix(0.22f, 0.42f, exp(-pow(ray.dx / 0.26f, 2.0f))), fall);
    return s;
}

/// The sun alone, in linear light: heart, corona, bloom; out of focus it spreads wider and dimmer. `heart` is its core,
/// for the extended range.
static float3 sunLayer(float2 p, constant SkyUniforms &u, thread float &heart) {
    float defocus = clamp(u.sunDefocus, 0.0f, 1.0f);
    float R = 0.13f * u.frameSize.y * (1.0f + defocus * 2.2f);
    float2 d = (p - u.sun) * u.sunAspect;
    float r = length(d);
    float dim = 1.0f / (1.0f + defocus * 2.4f);
    heart = exp(-pow(r / R, 2.2f)) * dim;
    float corona = exp(-pow(r / (R * 2.0f), 1.8f)) * dim;
    float bloom = exp(-pow(r / (R * 3.8f), 1.5f));
    // A wide, faint warmth around it, reaching across the screen while it is out of focus (the owner, 2026-11-21:
    // "a wider surface to still cover the screen"); in focus, the window's sky gives the warmth instead.
    float wash = exp(-r / (u.frameSize.y * 1.1f)) * 0.22f * defocus;
    // Under the horizon the haze takes its lower part, once it is in focus.
    float below = max(p.y - u.sun.y, 0.0f) / u.frameSize.y;
    float hide = mix(1.0f - smoothstep(0.0f, 0.14f, below), 1.0f, defocus);
    heart *= hide;
    return float3(3.0f, 2.05f, 0.85f) * heart * 0.9f + float3(1.8f, 0.60f, 0.18f) * corona * 0.6f * (0.45f + 0.55f * hide)
        + float3(0.9f, 0.25f, 0.16f) * bloom * 0.45f + float3(0.95f, 0.45f, 0.25f) * wash;
}

static float3 toneMap(float3 lit) {
    float lum = dot(lit, float3(0.2126f, 0.7152f, 0.0722f));
    lit = max(lum + (lit - lum) * 1.08f, 0.0f);
    return clamp((lit * (2.51f * lit + 0.03f)) / (lit * (2.43f * lit + 0.59f) + 0.14f), 0.0f, 1.0f);
}

fragment float4 sky_fragment(SkyVertex in [[stage_in]], constant SkyUniforms &u [[buffer(0)]]) {
    float2 p = in.position.xy / u.scale;
    // How much more light than white the display gives; kept moderate (a sun, not a flash).
    float extra = clamp(u.headroom, 1.0f, 4.0f) - 1.0f;

    float2 uv = (p - u.frameOrigin) / max(u.frameSize, float2(1.0f));
    SkyRay ray = skyRay(uv, u.frameSize.x / max(u.frameSize.y, 1.0f), u);
    float heart = 0.0f;
    float3 sun = sunLayer(p, u, heart) * u.sunOpacity;
    float3 sky = u.skyOpacity > 0.0f ? skyLayer(ray, u) * 0.97f * u.skyOpacity : float3(0.0f);

    float3 color = toneMap(sky + sun * 0.97f);
    // The sun's heart past white, as bright as the display allows.
    color += float3(1.0f, 0.86f, 0.62f) * pow(heart, 1.4f) * extra * 0.7f * u.sunOpacity;
    color += (skyHash(in.position.xy + fract(u.time) * 17.0f) - 0.5f) * 0.004f * u.skyOpacity;
    // Alone, the sun is its own light over what is behind it: as opaque as it is bright.
    float sunAlpha = clamp(dot(toneMap(sun), float3(0.2126f, 0.7152f, 0.0722f)) * 1.6f, 0.0f, 1.0f);
    float alpha = clamp(u.skyOpacity + sunAlpha * (1.0f - u.skyOpacity), 0.0f, 1.0f);
    return float4(max(color, 0.0f), alpha);
}
