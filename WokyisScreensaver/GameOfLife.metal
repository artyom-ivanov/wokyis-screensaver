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
    out.uv = float2((p.x + 1.0) * 0.5, 1.0 - (p.y + 1.0) * 0.5);
    return out;
}

fragment float4 fs_gol(VSOutGol in [[stage_in]],
                      constant GoLUniforms &u [[buffer(0)]],
                      texture2d<uint, access::read> grid [[texture(0)]]) {
    uint2 size = uint2(grid.get_width(), grid.get_height());
    float2 cellPos = in.uv * float2(size);
    uint2 cellCoord = uint2(clamp(cellPos, float2(0.0), float2(size) - 1.0));

    uint4 cellData = grid.read(cellCoord);
    uint state    = cellData.r;
    uint trail    = cellData.g;
    uint trailCol = cellData.b;

    float2 local = cellPos - floor(cellPos);
    if (local.x < u.cellInset || local.x > 1.0 - u.cellInset ||
        local.y < u.cellInset || local.y > 1.0 - u.cellInset) {
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    if (state == 1u) return float4(u.colorA, 1.0);
    if (state == 2u) return float4(u.colorB, 1.0);

    if (trail > 0u) {
        float3 c = (trailCol == 1u) ? u.colorA : u.colorB;
        float alpha = pow(float(trail) / 255.0, 0.55) * 0.9;
        return float4(c * alpha, 1.0);
    }

    return float4(0.0, 0.0, 0.0, 1.0);
}

// One Conway generation with team inheritance + trail decay. Toroidal grid.
kernel void gol_step(texture2d<uint, access::read>  src [[texture(0)]],
                     texture2d<uint, access::write> dst [[texture(1)]],
                     constant uint &trailDecay [[buffer(0)]],
                     uint2 gid [[thread_position_in_grid]]) {
    uint w = src.get_width();
    uint h = src.get_height();
    if (gid.x >= w || gid.y >= h) return;

    uint x = gid.x, y = gid.y;
    uint xL = (x == 0u)     ? w - 1u : x - 1u;
    uint xR = (x == w - 1u) ? 0u     : x + 1u;
    uint yU = (y == 0u)     ? h - 1u : y - 1u;
    uint yD = (y == h - 1u) ? 0u     : y + 1u;

    uint nA = 0u, nB = 0u;
#define TALLY(cx, cy) { uint v = src.read(uint2((cx), (cy))).r; \
                       if (v == 1u) nA++; else if (v == 2u) nB++; }
    TALLY(xL, yU); TALLY(x, yU); TALLY(xR, yU);
    TALLY(xL, y);                 TALLY(xR, y);
    TALLY(xL, yD); TALLY(x, yD); TALLY(xR, yD);
#undef TALLY

    uint4 self = src.read(gid);
    uint current = self.r;
    uint nTotal = nA + nB;
    uint nextVal;
    if (current != 0u) {
        nextVal = (nTotal == 2u || nTotal == 3u) ? current : 0u;
    } else {
        nextVal = (nTotal == 3u) ? (nA > nB ? 1u : 2u) : 0u;
    }

    uint newTrail = self.g;
    uint newTrailCol = self.b;
    if (nextVal != 0u) {
        newTrail = 255u;
        newTrailCol = nextVal;
    } else if (self.g > 0u) {
        newTrail = (self.g >= trailDecay) ? self.g - trailDecay : 0u;
    }

    dst.write(uint4(nextVal, newTrail, newTrailCol, 0u), gid);
}
