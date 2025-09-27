#include <metal_stdlib>
using namespace metal;

// ---------- sRGB <-> Linear ----------
inline float3 srgb_to_linear(float3 c) {
    return select(c / 12.92, pow((c + 0.055) / 1.055, 2.4), c > 0.04045);
}
inline float3 linear_to_srgb(float3 c) {
    return select(c * 12.92, 1.055 * pow(c, 1.0 / 2.4) - 0.055, c > 0.0031308);
}

// ---------- CPU <-> GPU params (must match Swift) ----------
struct Params {
    float time, speed, scale, warp, edge, separation, contrast;
    float2 aspect;
    float4 color1, color2, color3, color4, color5, color6;
    float mask1, mask2, mask3, mask4, mask5, mask6;
    float intensity1, intensity2, intensity3, intensity4, intensity5, intensity6;
};

struct VOut { float4 position [[position]]; float2 uv; };

// ---------- Noise ----------
inline float hash21(float2 p){
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}
inline float valueNoise(float2 p){
    float2 i = floor(p), f = fract(p);
    float a=hash21(i), b=hash21(i+float2(1,0)), c=hash21(i+float2(0,1)), d=hash21(i+float2(1,1));
    float2 u = f*f*(3.0-2.0*f);
    return mix(a,b,u.x) + (c-a)*u.y*(1.0-u.x) + (d-b)*u.x*u.y;
}
inline float fbm(float2 p){
    float v = 0.0, a = 0.5;
    for (int i=0;i<5;++i){ v += a * valueNoise(p); p = p*2.0 + 10.5; a *= 0.5; }
    return v;
}

// ---------- Divergence-free warp (curl noise) ----------
inline float2 curlNoise(float2 p) {
    const float e = 0.75;
    float n10 = fbm(p + float2(0,  e));
    float n20 = fbm(p + float2(0, -e));
    float n01 = fbm(p + float2( e, 0));
    float n02 = fbm(p + float2(-e, 0));
    float2 g = float2(n10 - n20, n01 - n02) / (2.0 * e);
    return float2(g.y, -g.x); // rotate gradient 90°
}
inline float2 warpIncompressible(float2 p, float t, float s){
    float2 v = curlNoise(p*1.2 + t*0.05);
    return p + s * v;
}

// ---------- Dye absorption (Beer–Lambert helpers) ----------
inline float3 absorptionFromSRGB(float3 srgb) {
    float3 lin = srgb_to_linear(srgb);
    return max(float3(0.04), 1.0 - lin); // small floor for realism & stability
}

// ---------- Vertex ----------
vertex VOut vertex_main(const device float2* vertices [[buffer(0)]], uint vid [[vertex_id]]) {
    VOut o; float2 pos = vertices[vid]; o.position=float4(pos,0,1); o.uv=(pos+1.0)*0.5; return o;
}

// ---------- Fragment ----------
fragment float4 fragment_main(VOut in [[stage_in]], constant Params& P [[buffer(0)]]) {
    
    // If nothing is enabled, render a dim gray (not transparent)
    float sumMasks = P.mask1 + P.mask2 + P.mask3 + P.mask4 + P.mask5 + P.mask6;
    if (sumMasks < 0.5) {
        const float3 GRAY = float3(0); // linear ~18% gray
        return float4(linear_to_srgb(GRAY), 1.0);
    }
    
    // Coords / time
    float2 p = in.uv*2.0-1.0; p.x *= P.aspect.x;
    float t = P.time * P.speed;
    
    // Incompressible flow → natural plume stretching/folding
    float2 q = warpIncompressible(p * P.scale, t, P.warp);
    
    // Six evolving scalar fields (one per dye)
    float n1 = fbm(q*1.00 + float2( 3.1,-2.7) + t*0.05);
    float n2 = fbm(q*0.95 + float2(-7.3,11.7) - t*0.04);
    float n3 = fbm(q*1.05 + float2(17.9, 5.6) + t*0.03);
    float n4 = fbm(q*0.90 + float2(-9.4,-8.2) + t*0.06);
    float n5 = fbm(q*1.10 + float2(12.0, 9.7) - t*0.05);
    float n6 = fbm(q*0.85 + float2( 6.5,-4.3) + t*0.02);
    
    // Shape fields
    float g = max(0.0001, P.contrast);
    float vals[6] = {
        pow(clamp(n1,0.0,1.0), g),
        pow(clamp(n2,0.0,1.0), g),
        pow(clamp(n3,0.0,1.0), g),
        pow(clamp(n4,0.0,1.0), g),
        pow(clamp(n5,0.0,1.0), g),
        pow(clamp(n6,0.0,1.0), g)
    };
    
    // Build dye concentrations
    float masks[6] = { P.mask1, P.mask2, P.mask3, P.mask4, P.mask5, P.mask6 };
    float intens[6]= { P.intensity1, P.intensity2, P.intensity3, P.intensity4, P.intensity5, P.intensity6 };
    float3 cols_srgb[6] = { P.color1.rgb, P.color2.rgb, P.color3.rgb, P.color4.rgb, P.color5.rgb, P.color6.rgb };
    
    
    // Double the effective intensity *here* (rendering only)
    const float kIntensityScale = 3.0;
    
    float sharp = mix(1.0, 6.0, clamp(P.separation / 10.0, 0.0, 1.0));
    float d[6];
    for (int i=0;i<6;++i) {
        float enabled = (masks[i] > 0.5) ? 1.0 : 0.0;
        d[i] = enabled * pow(vals[i], sharp) * max(0.0, intens[i] * kIntensityScale); // allows >1 intensity
    }
    
    // Optical thickness (edge slider repurposed: 0→thin, 1→dense)
    float thickness = mix(0.35, 3.0, clamp(P.edge, 0.0, 1.0));
    
    // --- Beer–Lambert in linear space ---
    float3 sigma[6] = {
        absorptionFromSRGB(cols_srgb[0]),
        absorptionFromSRGB(cols_srgb[1]),
        absorptionFromSRGB(cols_srgb[2]),
        absorptionFromSRGB(cols_srgb[3]),
        absorptionFromSRGB(cols_srgb[4]),
        absorptionFromSRGB(cols_srgb[5])
    };
    
    float3 OD = float3(0.0);
    for (int i=0;i<6;++i) { OD += d[i] * sigma[i]; }
    float3 Tmix = exp(-thickness * OD); // linear-space transmittance
    
    // --- Lightness preservation (gated for thin mixes) ---
    const float3 LUMA = float3(0.2126, 0.7152, 0.0722);
    float Y_mix = dot(Tmix, LUMA);
    
    float sumd = d[0]+d[1]+d[2]+d[3]+d[4]+d[5];
    
    float Y_target = Y_mix;
    if (sumd > 1e-5) {
        Y_target = 0.0;
        for (int i=0;i<6;++i) {
            if (d[i] > 0.0) {
                float3 Ti = exp(-thickness * (d[i] * sigma[i]));
                float wi = d[i] / sumd;
                Y_target += wi * dot(Ti, LUMA);
            }
        }
    }
    
    // Measure total "amount" from UI intensities to gate brightening for thin mixes.
    float S = 0.0;
    for (int i=0;i<6;++i) {
        float enabled = (masks[i] > 0.5) ? 1.0 : 0.0;
        S += enabled * max(0.0, intens[i]); // works with 0..2 if renderer scales
    }
    
    // Gate: below S_HI no/light compensation; above it, original behavior.
    // map S to [0..1]: 0=thin, 1=full
    const float S_LO = 0.0;
    const float S_HI = 4.0; // your threshold
    float wThin = smoothstep(S_LO, S_HI, S); // 0→thin, 1→full
    
//    Increase toward 1.0 for stronger compensation (brighter results).
//    Decrease toward 0.0 for weaker (more strictly physical/inkier).
    const float preserve = 0.45; // 0 = physical, 1 = stronger preservation
    float gain_raw = pow((Y_target + 1e-5) / (Y_mix + 1e-5), preserve);
    float gain = mix(1.0, gain_raw, wThin); // no brightening for thin mixes
    
    float3 Tcomp = saturate(Tmix * gain);
    
    // --- Dim to gray when thin/empty ---
    const float3 GRAY = float3(0);           // linear gray floor
    float3 Tdimmed = mix(GRAY, Tcomp, wThin);   // when S→0, show gray; ramps to Tcomp
    
    // Back to sRGB color
    float3 c = linear_to_srgb(Tdimmed);
    
    // Subtle billowy shading (depth cue)
    float dens = sumd;
    float dx = dfdx(dens), dy = dfdy(dens);
    float3 N = normalize(float3(-dx, -dy, 0.5));
    float3 L = normalize(float3(0.3, 0.6, 1.0));
    float shade = clamp(dot(N, L), 0.0, 1.0);
    c *= (0.85 + 0.25 * shade);
    
    return float4(clamp(c, 0.0, 1.0), 1.0);
}
