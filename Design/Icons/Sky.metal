// Sunset's sky, for its icons (roadmap 0084). Drawn by RenderIcon.swift; see there for how it is run.
// Rayleigh, Mie and ozone single scattering through a spherical atmosphere; the sun a glow half under a haze; faint lens
// distortion, heat shimmer, chromatic aberration and fine round grain.
#include <metal_stdlib>
using namespace metal;

struct IconUniforms {
    float2 resolution;
    float sunElevationDeg;
    float exposure;
    float turbidity;
    float ozoneStrength;
    float chromaticStrength;
    float grainStrength;
    float sunDrop; float coreSize; float curve; float mistSoft; float pale; float burn; float airy; float day; float gold; float night; int layerMode; // 0 = full composite (default), 1 = solar aureole layer (alpha PNG for Icon Composer), 2 = dark mode composite, 3 = tinted/mono, 4 = soft horizon haze layer (alpha PNG for Icon Composer)
};

static inline float hash12(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031f);
    p3 += dot(p3, p3.yzx + 33.33f);
    return fract((p3.x + p3.y) * p3.z);
}

// Subtle, fine rounded silver-halide grain
static inline float roundedGrain(float2 pixelCoord) {
    float2 gCoord = pixelCoord / 1.32f;
    float2 base = floor(gCoord);
    float2 f = fract(gCoord);
    float2 w = f * f * (3.0f - 2.0f * f);
    float b1 = mix(
        mix(hash12(base), hash12(base + float2(1,0)), w.x),
        mix(hash12(base + float2(0,1)), hash12(base + float2(1,1)), w.x),
        w.y
    );
    float2 gCoord2 = (pixelCoord + float2(0.53f, 0.41f)) / 0.88f;
    float2 base2 = floor(gCoord2);
    float2 f2 = fract(gCoord2);
    float2 w2 = f2 * f2 * (3.0f - 2.0f * f2);
    float b2 = mix(
        mix(hash12(base2 + 19.3f), hash12(base2 + float2(1,0) + 19.3f), w2.x),
        mix(hash12(base2 + float2(0,1) + 19.3f), hash12(base2 + float2(1,1) + 19.3f), w2.x),
        w2.y
    );
    return b1 - b2;
}

static inline float vnoise(float2 p) {
    float2 i = floor(p), f = fract(p), w = f * f * (3.0f - 2.0f * f);
    return mix(mix(hash12(i), hash12(i + float2(1, 0)), w.x), mix(hash12(i + float2(0, 1)), hash12(i + float2(1, 1)), w.x), w.y);
}

static inline float3 linearToSRGB(float3 c) {
    float3 lo = c * 12.92f;
    float3 hi = 1.055f * pow(max(c, float3(0.0f)), float3(1.0f / 2.4f)) - 0.055f;
    return select(hi, lo, c <= 0.0031308f);
}

static inline float3 acesToneMap(float3 x) {
    return clamp((x * (2.51f * x + 0.03f)) / (x * (2.43f * x + 0.59f) + 0.14f), 0.0f, 1.0f);
}

// Pure cloud-free Rayleigh + Mie + Ozone Chappuis scattering
static float3 evalPureAtmosphere(float3 dir, float sunElevRad, float turbidity, float ozoneStrength) {
    float3 sunDir = normalize(float3(0.0f, sin(sunElevRad), cos(sunElevRad)));
    const float Re = 6371.0f, Ra = 6471.0f, Hr = 8.0f, Hm = 1.35f;
    const float3 betaR = float3(0.005802f, 0.013558f, 0.033100f);
    const float3 betaMScat = float3(0.003996f) * turbidity;
    const float3 betaMExt  = float3(0.004440f) * turbidity;
    const float3 betaO = float3(0.000650f, 0.001881f, 0.000085f) * ozoneStrength;

    // Gentle asymptotic curve near and below horizon so there is never a sharp bend
    float smoothY = 0.5f * (dir.y + sqrt(dir.y * dir.y + 0.0045f)) + 0.003f;
    float3 rDir = normalize(float3(dir.x, smoothY, dir.z));
    float3 origin = float3(0.0f, Re + 0.22f, 0.0f);
    float b = dot(origin, rDir);
    float c = dot(origin, origin) - Ra * Ra;
    float tMax = -b + sqrt(max(b * b - c, 0.0f));

    float cosTheta = dot(rDir, sunDir);
    float phaseR = 3.0f / (16.0f * 3.14159265f) * (1.0f + cosTheta * cosTheta);
    float g = 0.78f, g2 = g * g;
    float phaseM = 3.0f / (8.0f * 3.14159265f) * ((1.0f - g2) * (1.0f + cosTheta * cosTheta)) / ((2.0f + g2) * pow(max(1.0f + g2 - 2.0f * g * cosTheta, 0.001f), 1.5f));

    float optR = 0.0f, optM = 0.0f, optO = 0.0f;
    float3 sumR = float3(0.0f), sumM = float3(0.0f), sumMulti = float3(0.0f);

    for (int i = 0; i < 20; i++) {
        float u0 = float(i) / 20.0f, u1 = float(i + 1) / 20.0f;
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
        float dtSun = tSunMax / 8.0f;
        float sR = 0, sM = 0, sO = 0;
        for (int j = 0; j < 8; j++) {
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

    // Belt of Venus twilight rose-magenta + warm horizon afterglow
    float twilight = clamp(1.0f - abs(sunElevRad + 0.018f) / 0.16f, 0.0f, 1.0f);
    sky += float3(0.68f, 0.16f, 0.38f) * twilight * exp(-pow((rDir.y - 0.14f) / 0.12f, 2.0f)) * 0.24f;
    sky += float3(1.15f, 0.32f, 0.10f) * twilight * exp(-pow(rDir.y / 0.085f, 2.0f)) * 0.32f;

    return sky;
}

static float3 sampleDiffusedSunsetIcon(float2 p, float elevRad, float turbidity, float ozoneStrength, float darkFactor,
                                       float sunDrop, float coreSize, float curve, float mistSoft, float pale, float burn, float airy, float day, float gold, float night) {
    // No ground and no line: the sky goes on down into a thick low haze that darkens over a large part of the icon,
    // as a sunset seen through haze or sea mist does. Everything below is continuous (no mirror, no kink).
    float dx = p.x - 0.5f;
    float horizonY = 0.76f + dx * dx * curve;
    float dy = p.y - horizonY;
    // Pitch eases to 0 at the horizon and stays there: below it the colour is the horizon's, carried down smoothly.
    float above = max(-dy, 0.0f);
    float pitch = above * 0.78f;
    float yaw = dx * 1.04f;
    float3 dir = normalize(float3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)));
    float3 s = evalPureAtmosphere(dir, elevRad, turbidity, ozoneStrength) * 0.54f;

    // The sun: only glow (core, corona, bloom), no disc; its centre `sunDrop` of its radius under the horizon.
    float R = coreSize;
    float2 c = float2(0.50f, 0.76f + sunDrop * R);
    float r = length((p - c) * float2(0.92f, 1.08f));
    float core = exp(-pow(r / R, 2.2f));
    float corona = exp(-pow(r / (R * 2.0f), 1.8f));
    float bloom = exp(-pow(r / (R * 3.8f), 1.5f));
    // The haze swallows its lower part over a wide gradient.
    float hide = 1.0f - smoothstep(-mistSoft * 0.6f, mistSoft * 1.8f, dy);
    float3 cCore = mix(mix(float3(3.0f, 2.05f, 0.85f), float3(2.7f, 2.05f, 1.85f), pale), float3(2.9f, 1.05f, 0.30f), burn);
    float3 cCor = mix(mix(float3(1.8f, 0.60f, 0.18f), float3(1.55f, 0.62f, 0.62f), pale), float3(1.6f, 0.30f, 0.07f), burn);
    float3 cBloom = mix(mix(float3(0.9f, 0.25f, 0.16f), float3(0.85f, 0.34f, 0.44f), pale), float3(0.85f, 0.14f, 0.06f), burn);
    // Daylight: a white-gold sun, a pale blue haze; gold warms it toward the afternoon's.
    float3 dCore = mix(float3(2.6f, 2.5f, 2.3f), float3(2.9f, 2.4f, 1.6f), gold);
    float3 dCor = mix(float3(1.05f, 0.98f, 0.86f), float3(1.30f, 0.95f, 0.55f), gold);
    float3 dBloom = mix(float3(0.40f, 0.46f, 0.56f), float3(0.62f, 0.50f, 0.40f), gold);
    cCore = mix(cCore, dCore, day); cCor = mix(cCor, dCor, day); cBloom = mix(cBloom, dBloom, day);
    // Night: the moon's cool silver light in the sun's place.
    cCore = mix(cCore, float3(1.55f, 1.70f, 2.05f), night); cCor = mix(cCor, float3(0.42f, 0.52f, 0.78f), night);
    cBloom = mix(cBloom, float3(0.12f, 0.18f, 0.36f), night);
    s += cCore * core * mix(0.9f, 0.7f, pale) * hide;
    s += cCor * corona * 0.6f * (0.45f + 0.55f * hide);
    s += cBloom * bloom * 0.45f * (1.0f - 0.45f * day);

    // The haze band: warm, wide, brightest just above where the horizon would be.
    s += mix(mix(mix(float3(0.95f, 0.42f, 0.26f), float3(0.95f, 0.55f, 0.58f), pale), float3(0.80f, 0.22f, 0.08f), burn), mix(float3(0.78f, 0.88f, 1.0f), float3(1.0f, 0.86f, 0.70f), gold), day) * exp(-pow((dy + mistSoft * 0.3f) / (mistSoft * 2.4f), 2.0f)) * 0.30f;
    // Pale: the sky lifted toward a cool lavender-blue; burn: the sky's blue drained, the whole deeper.
    // Twilight: a clear blue overhead, a true pink low down (not lavender: the red is taken out above, the blue out below).
    float up = smoothstep(0.04f, 0.42f, above);
    float3 paleTint = mix(float3(1.06f, 0.80f, 0.88f), float3(0.62f, 0.86f, 1.18f), up);
    s = mix(s, s * paleTint + mix(float3(0.020f, 0.008f, 0.012f), float3(0.004f, 0.012f, 0.030f), up), pale);
    s = mix(s, s * float3(0.82f, 0.56f, 0.42f), burn);
    // Daylight: the sky cleared toward a clean blue overhead, a bright pale haze low down instead of the dark.
    float3 dayTint = mix(float3(1.04f, 1.0f, 0.97f), float3(0.74f, 0.95f, 1.26f), up);
    s = mix(s, s * dayTint * 1.1f, day);
    // Gold: the afternoon's (and the sunrise's) warmth, low down most.
    s = mix(s, s * mix(float3(1.16f, 1.0f, 0.78f), float3(1.06f, 1.0f, 0.92f), up), gold * day);
    // Night: a deep blue overhead, a little lighter toward the horizon, a few soft stars high up.
    float3 nightSky = mix(float3(0.030f, 0.045f, 0.095f), float3(0.006f, 0.010f, 0.032f), up);
    float2 cell = floor(p * 46.0f);
    float star = step(0.985f, hash12(cell)) * exp(-pow(length(fract(p * 46.0f) - 0.5f) / 0.09f, 2.0f));
    star *= smoothstep(0.10f, 0.45f, above) * (0.5f + 0.5f * hash12(cell + 7.0f));
    s = mix(s, s * float3(0.30f, 0.40f, 0.80f) + nightSky + float3(0.55f, 0.60f, 0.75f) * star, night);
    // Dawn (airy): halfway (dawnMix) between two looks the owner picked on 2026-11-19:
    //  - "sheet 9": twilight pushed along its own direction (bluer above, pinker below), lifted toward white where dark;
    //  - "sheet 11": a white pastel sky, pink low down, white around the sun, powder blue above, light everywhere.
    const float dawnMix = 0.40f;
    float3 airyTint = mix(float3(1.08f, 0.80f, 0.90f), float3(0.62f, 0.94f, 1.16f), up);
    float3 pushed = s * airyTint * 1.30f;
    float pl = dot(pushed, float3(0.2126f, 0.7152f, 0.0722f));
    pushed = mix(pushed, float3(0.92f, 0.90f, 0.96f), 0.20f * (1.0f - clamp(pl, 0.0f, 1.0f)));

    float hy = 1.0f - p.y;
    float3 blush  = float3(1.00f, 0.40f, 0.60f);
    float3 pearl  = float3(1.00f, 0.91f, 0.94f);
    float3 powder = float3(0.26f, 0.58f, 1.00f);
    float3 pastel = mix(blush, pearl, smoothstep(0.10f, 0.42f, hy));
    pastel = mix(pastel, powder, smoothstep(0.48f, 0.98f, hy));
    float lum = dot(s, float3(0.2126f, 0.7152f, 0.0722f));
    float3 white = pastel * mix(1.05f, 1.75f, clamp(lum * 1.6f, 0.0f, 1.0f)) + s * 0.18f;

    s = mix(s, mix(pushed, white, dawnMix), airy);
    // Darkening below, over a long distance, warmer under the sun.
    float fall = smoothstep(-mistSoft * 0.5f, mistSoft * 7.0f, dy);
    float under = exp(-pow(dx / 0.26f, 2.0f));
    s *= mix(1.0f, mix(mix(0.22f, 0.42f, under), mix(0.86f, 0.94f, under), day), fall);
    s += mix(float3(0.42f, 0.48f, 0.58f), float3(0.52f, 0.42f, 0.30f), gold) * fall * day * 0.35f;

    s *= mix(1.0f, 0.54f, darkFactor);
    return s;
}

struct VertexOut { float4 position [[position]]; float2 uv; };

vertex VertexOut icon_vertex(uint vid [[vertex_id]]) {
    float2 pos[4] = { {-1,-1}, {1,-1}, {-1,1}, {1,1} };
    float2 uv[4]  = { {0,1}, {1,1}, {0,0}, {1,0} };
    VertexOut out; out.position = float4(pos[vid], 0, 1); out.uv = uv[vid]; return out;
}

fragment float4 icon_fragment(VertexOut in [[stage_in]], constant IconUniforms &u [[buffer(0)]]) {
    float2 uv = in.uv;
    float2 px = uv * u.resolution;

    if (u.layerMode == 1) {
        // Layer 1 for Icon Composer: Soft diffused solar core & Mie aureole (transparent PNG)
        float2 sunUV = float2(0.50f, 0.545f);
        float2 d = uv - sunUV;
        float dist = length(d * float2(0.96f, 1.04f));
        float core = exp(-pow(dist / 0.145f, 2.5f));
        float corona = exp(-pow(dist / 0.265f, 2.0f));
        float outer = exp(-pow(dist / 0.46f, 1.8f));
        float3 col = mix(float3(1.0f, 0.40f, 0.20f), float3(1.0f, 0.88f, 0.54f), clamp(core * 1.15f + corona * 0.35f, 0.0f, 1.0f));
        float alpha = clamp(core * 0.92f + corona * 0.58f + outer * 0.28f, 0.0f, 0.96f);
        col = clamp(col + roundedGrain(px) * 0.0035f, 0.0f, 1.0f);
        return float4(col * alpha, alpha);
    }

    if (u.layerMode == 4) {
        // Layer 2 for Icon Composer: Gently curved twilight mist veil rising from bottom (transparent PNG)
        float dx = uv.x - 0.5f;
        float curvedY = 0.665f + dx * dx * 0.14f;
        float dy = uv.y - curvedY;
        float mist = smoothstep(-0.09f, 0.28f, dy);
        float pillar = exp(-pow(dx / mix(0.16f, 0.36f, clamp(dy / 0.35f, 0.0f, 1.0f)), 2.0f)) * exp(-pow(max(dy, 0.0f) / 0.32f, 1.6f));
        float3 baseCol = mix(float3(0.24f, 0.12f, 0.28f), float3(0.95f, 0.44f, 0.26f), clamp(pillar * 1.3f, 0.0f, 1.0f));
        float alpha = clamp(mist * 0.62f + pillar * 0.28f, 0.0f, 0.78f);
        baseCol = clamp(baseCol + roundedGrain(px) * 0.0035f, 0.0f, 1.0f);
        return float4(baseCol * alpha, alpha);
    }

    // Optics, kept faint: what a real lens and real air do to the picture.
    //  - barrel distortion, k = 0.04 at the corners (a wide lens's, small): the horizon bows a little more toward the edges;
    //  - heat shimmer: the low air near the sun bends its light; a slow, smooth displacement, a few thousandths of the icon,
    //    strongest at the glow and the horizon band, nothing at the top;
    //  - chromatic aberration (below): red and blue separate toward the edges.
    {
        float2 c = uv - 0.5f;
        float r2 = dot(c, c);
        uv = 0.5f + c * (1.0f + 0.04f * r2 * 2.0f);
        float band = exp(-pow((uv.y - 0.80f) / 0.16f, 2.0f));
        float2 w = float2(vnoise(float2(uv.x * 7.0f, uv.y * 22.0f) + 3.1f), vnoise(float2(uv.x * 9.0f + 5.7f, uv.y * 18.0f))) - 0.5f;
        uv += w * float2(0.0030f, 0.0050f) * band;
    }
    float2 centered = uv - 0.5f;
    float radial = length(centered);
    float ca = u.chromaticStrength * 0.0034f * radial * radial;
    float2 off = radial > 1e-5f ? (centered / radial) * ca : float2(0.0f);
    float elevRad = u.sunElevationDeg * (3.14159265f / 180.0f);
    float darkF = (u.layerMode == 2) ? 1.0f : 0.0f;

    float r = sampleDiffusedSunsetIcon(uv + off, elevRad, u.turbidity, u.ozoneStrength, darkF, u.sunDrop, u.coreSize, u.curve, u.mistSoft, u.pale, u.burn, u.airy, u.day, u.gold, u.night).r;
    float g = sampleDiffusedSunsetIcon(uv,       elevRad, u.turbidity, u.ozoneStrength, darkF, u.sunDrop, u.coreSize, u.curve, u.mistSoft, u.pale, u.burn, u.airy, u.day, u.gold, u.night).g;
    float b = sampleDiffusedSunsetIcon(uv - off, elevRad, u.turbidity, u.ozoneStrength, darkF, u.sunDrop, u.coreSize, u.curve, u.mistSoft, u.pale, u.burn, u.airy, u.day, u.gold, u.night).b;

    // A slight lift for every variant: 5% more light, 8% more saturation around each pixel's own luminance (linear light).
    float3 lit = float3(r, g, b) * u.exposure * 1.05f;
    float lLit = dot(lit, float3(0.2126f, 0.7152f, 0.0722f));
    lit = max(lLit + (lit - lLit) * 1.08f, 0.0f);
    float3 ldr = linearToSRGB(acesToneMap(lit));
    float grain = roundedGrain(px) * u.grainStrength;
    ldr = clamp(ldr + grain, 0.0f, 1.0f);

    if (u.layerMode == 3) {
        float lum = dot(ldr, float3(0.2126f, 0.7152f, 0.0722f));
        float boosted = clamp(pow(lum, 1.08f) * 1.14f, 0.0f, 1.0f);
        return float4(float3(boosted), 1.0f);
    }

    return float4(ldr, 1.0f);
}
