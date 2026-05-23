#include <metal_stdlib>
using namespace metal;

struct GoLUniforms {
    float2 gridSize;       // cols, rows
    float2 viewportSize;
    float3 colorA;
    float3 colorB;
    float  cellInset;      // 0..0.5
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
    // Texture origin is top-left in our upload layout; flip y.
    out.uv = float2((p.x + 1.0) * 0.5, 1.0 - (p.y + 1.0) * 0.5);
    return out;
}

fragment float4 fs_gol(VSOutGol in [[stage_in]],
                      constant GoLUniforms &u [[buffer(0)]],
                      texture2d<float> grid [[texture(0)]]) {
    float2 uv = in.uv;

    constexpr sampler s(filter::nearest, address::clamp_to_edge);
    float4 cellData = grid.sample(s, uv);

    int state    = int(round(cellData.r * 255.0));
    int trail    = int(round(cellData.g * 255.0));
    int trailCol = int(round(cellData.b * 255.0));

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
