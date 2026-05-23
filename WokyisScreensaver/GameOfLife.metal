#include <metal_stdlib>
using namespace metal;

struct GoLUniforms {
    float2 gridSize;       // cols, rows
    float2 viewportSize;
    float3 colorA;
    float3 colorB;
    float  wipeProgress;   // -1 if not wiping, else 0..1
    float  bandFraction;   // 0..1, fraction of width
    float  cellInset;      // 0..0.5
    float  _pad;           // align stride to 16
};

struct VSOutGol {
    float4 position [[position]];
    float2 uv;
};

vertex VSOutGol vs_gol(uint vid [[vertex_id]]) {
    float2 p = float2((vid == 1) ? 3.0 : -1.0,
                      (vid == 2) ? 3.0 : -1.0);
    VSOutGol out;
    out.position = float4(p, 0.0, 1.0);
    // Flip y because texture has origin top-left in our upload layout.
    out.uv = float2((p.x + 1.0) * 0.5, 1.0 - (p.y + 1.0) * 0.5);
    return out;
}

fragment float4 fs_gol(VSOutGol in [[stage_in]],
                      constant GoLUniforms &u [[buffer(0)]],
                      texture2d<float> gridNew [[texture(0)]],
                      texture2d<float> gridOld [[texture(1)]]) {
    float2 uv = in.uv;

    bool wiping = (u.wipeProgress >= 0.0);
    float bandLeft = -u.bandFraction + u.wipeProgress * (1.0 + u.bandFraction);
    float bandRight = bandLeft + u.bandFraction;

    if (wiping && uv.x >= bandLeft && uv.x <= bandRight) {
        float3 g = mix(u.colorA, u.colorB, uv.y);
        return float4(g, 1.0);
    }

    bool useOld = (wiping && uv.x > bandRight);

    constexpr sampler s(filter::nearest, address::clamp_to_edge);
    float4 cellData = useOld ? gridOld.sample(s, uv) : gridNew.sample(s, uv);

    int state      = int(round(cellData.r * 255.0));
    int trail      = int(round(cellData.g * 255.0));
    int trailCol   = int(round(cellData.b * 255.0));

    // Per-cell inset: render the gutter as black so cells read as a grid.
    float2 cellPos = uv * u.gridSize;
    float2 local = cellPos - floor(cellPos);
    if (local.x < u.cellInset || local.x > 1.0 - u.cellInset ||
        local.y < u.cellInset || local.y > 1.0 - u.cellInset) {
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    if (state == 1) return float4(u.colorA, 1.0);
    if (state == 2) return float4(u.colorB, 1.0);

    if (trail > 0) {
        float3 c = (trailCol == 1) ? u.colorA : u.colorB;
        float alpha = pow(float(trail) / 255.0, 0.55) * 0.9;
        return float4(c * alpha, 1.0);
    }

    return float4(0.0, 0.0, 0.0, 1.0);
}
