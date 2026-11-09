shader_type spatial;
render_mode cull_back;
// ORBIT SHIFT - sphere skin shader. `style`:
// 0 solid  1 plasma swirl  2 banded gradient  3 pulse  4 glitch  5 starfield  6 metallic  7 void rim

uniform vec4 base_color : source_color = vec4(0.1, 0.94, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.49, 0.98, 1.0, 1.0);
uniform int style = 0;
uniform float energy = 1.5;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
    float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.6);
    vec2 uv = UV * vec2(6.0, 3.0);
    vec3 col = base_color.rgb;
    float glow = 0.45;
    float rim = 1.4;
    METALLIC = 0.0;
    ROUGHNESS = 0.45;

    if (style == 1) {
        float n = vnoise(uv * 2.0 + vec2(TIME * 0.8, -TIME * 0.5));
        float n2 = vnoise(uv * 4.0 - vec2(TIME * 0.6));
        col = mix(base_color.rgb, glow_color.rgb, smoothstep(0.3, 0.8, n * 0.6 + n2 * 0.4));
        glow = 0.7;
    } else if (style == 2) {
        float b = 0.5 + 0.5 * sin(UV.y * 18.0 + TIME * 1.5);
        col = mix(base_color.rgb, glow_color.rgb, b);
        glow = 0.55;
    } else if (style == 3) {
        float p = 0.5 + 0.5 * sin(TIME * 3.0);
        col = mix(base_color.rgb, glow_color.rgb, p * 0.6);
        glow = 0.35 + 0.55 * p;
    } else if (style == 4) {
        float g = step(0.92, hash21(vec2(floor(UV.y * 14.0), floor(TIME * 9.0))));
        col = mix(base_color.rgb, glow_color.rgb, g);
        glow = 0.45 + 0.9 * g;
    } else if (style == 5) {
        float s = step(0.965, hash21(floor(uv * 5.0)));
        float n = vnoise(uv * 1.5 + vec2(TIME * 0.05));
        col = mix(base_color.rgb * 0.45, base_color.rgb, n) + glow_color.rgb * s * 2.0;
        glow = 0.4;
    } else if (style == 6) {
        // fake environment reflection (no sky in the scene): vertical highlight bands
        float band = 0.5 + 0.5 * sin(NORMAL.y * 7.0 + NORMAL.x * 3.0 + TIME * 0.6);
        col = base_color.rgb * (0.55 + 0.9 * band);
        METALLIC = 0.8;
        ROUGHNESS = 0.2;
        glow = 0.5;
    } else if (style == 7) {
        col = base_color.rgb * 0.25;
        glow = 0.12;
        rim = 3.2;
    }

    ALBEDO = col * 0.35;
    EMISSION = col * glow * energy + glow_color.rgb * fres * rim;
}
