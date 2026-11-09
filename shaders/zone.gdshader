shader_type spatial;
render_mode cull_disabled, blend_add, unshaded, depth_draw_never;
// Hazard zone: dim warning pulse while harmless, bright + solid while deadly.

uniform vec4 color : source_color = vec4(1.0, 0.3, 0.37, 1.0);
uniform float state = 0.0;       // 0 = dormant, ~0.8 = warning, 1 = deadly
uniform float appear = 1.0;

void fragment() {
    float stripes = 0.5 + 0.5 * sin((UV.x + UV.y) * 60.0 - TIME * 4.0);
    float active_mix = smoothstep(0.9, 1.0, state);
    float a = mix(0.10 + 0.22 * state * (0.6 + 0.4 * stripes), 0.78, active_mix);
    ALBEDO = color.rgb * (0.6 + 0.9 * active_mix);
    ALPHA = a * appear;
}
