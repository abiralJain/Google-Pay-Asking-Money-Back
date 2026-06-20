//
//  Tremble.metal
//  GPay — Payment reminder
//
//  Nervous-message distortion. Amplitude is driven by the awkwardness
//  slider; at 0 the shader is a no-op.
//

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] float2 tremble(float2 position, float time, float amplitude) {
    if (amplitude <= 0.0) {
        return position;
    }
    float x = sin(position.y * 0.14 + time * 32.0) * amplitude;
    float y = cos(position.x * 0.10 + time * 26.0) * amplitude * 0.7;
    return position + float2(x, y);
}
