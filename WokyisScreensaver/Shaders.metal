#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float2 viewportSize;
    float  time;
};

struct VSOut {
    float4 position [[position]];
    float2 uv;
};

vertex VSOut vs_fullscreen(uint vid [[vertex_id]]) {
    // Three vertices form one large triangle covering the screen.
    // vid 0 -> (-1, -1), vid 1 -> (3, -1), vid 2 -> (-1, 3) in clip space.
    float2 p = float2((vid == 1) ? 3.0 : -1.0,
                      (vid == 2) ? 3.0 : -1.0);
    VSOut out;
    out.position = float4(p, 0.0, 1.0);
    // uv: 0..1 across the visible portion of the triangle.
    out.uv = (p + 1.0) * 0.5;
    return out;
}

fragment float4 fs_main(VSOut in [[stage_in]],
                        constant Uniforms &u [[buffer(0)]]) {
    float pulse = 0.5 + 0.5 * sin(u.time);
    return float4(in.uv.x * pulse, in.uv.y * pulse, 0.0, 1.0);
}
