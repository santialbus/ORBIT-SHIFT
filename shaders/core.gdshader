shader_type spatial;
render_mode cull_back;
// Central core: dark faceted metal with animated energy veins.

uniform vec4 core_color : source_color = vec4(0.05, 0.12, 0.36, 1.0);
uniform vec4 emit_color : source_color = vec4(0.17, 0.36, 1.0, 1.0);
uniform float pulse = 0.0;       // 0..1 boosted on pickups
uniform float intensity = 1.0;   // grows with combo

float hash21(vec2 p) { return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.5453); }

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
    float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
    float veins = smoothstep(0.62, 0.7, vnoise(UV * 7.0 + vec2(TIME * 0.25, TIME * 0.12)));
    float beat = 0.6 + 0.4 * sin(TIME * 1.6);
    ALBEDO = core_color.rgb * 0.5;
    METALLIC = 0.7;
    ROUGHNESS = 0.3;
    EMISSION = emit_color.rgb * (0.25 * beat + veins * 1.3 + fres * 1.4 + pulse * 1.2) * intensity;
}
