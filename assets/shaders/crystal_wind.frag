#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float starLayer(vec2 uv, float speed, float density, float brightnessFactor) {
    vec2 movement = vec2(uTime * speed * 0.02, -uTime * speed * 0.05); 
    vec2 gridUV = (uv + movement) * 40.0; 
    vec2 ipos = floor(gridUV); 
    vec2 fpos = fract(gridUV); 

    float rand = random(ipos);
    
    if (rand > (1.0 - density)) {
        vec2 center = vec2(0.5) + (vec2(random(ipos + 1.0), random(ipos - 1.0)) - 0.5) * 0.8;
        
        float dist = abs(fpos.x - center.x) + abs(fpos.y - center.y); 
        
        float shimmer = 0.5 + 0.5 * sin(uTime * 0.2 + rand * 100.0);
        shimmer = pow(shimmer, 1.5); 
        
        float size = 0.35 * (0.6 + 0.4 * rand); 
        float glow = 1.0 - smoothstep(0.0, size, dist);
        glow = pow(glow, 4.0);
        
        return glow * shimmer * brightnessFactor;
    }
    return 0.0;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    uv.x *= uSize.x / uSize.y;
    
    float light = 0.0;
    
    light += starLayer(uv, 0.05, 0.15, 1.5);
    light += starLayer(uv * 0.6, 0.1, 0.05, 2.0);
    light += starLayer(uv * 0.3, 0.15, 0.02, 3.0);

    // COLOR CHANGE: Dirty Gold / Pale White-Gold
    // R=1.0, G=0.92, B=0.75
    vec3 crystalColor = vec3(1.0, 0.92, 0.75);
    
    // TRANSPARENCY FIX:
    // We output 'light' as the Alpha channel.
    // This renders empty space as transparent.
    fragColor = vec4(crystalColor * light, light);
}