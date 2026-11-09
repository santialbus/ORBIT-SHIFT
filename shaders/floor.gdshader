shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
// Deep background plane under the orbits: radial gradient + faint expanding rings.

uniform vec4 base_color : source_color = vec4(0.02, 0.04, 0.09, 1.0);
uniform vec4 ring_color : source_color = vec4(0.25, 0.3, 0.9, 1.0);
uniform float speed = 0.12;

void fragment() {
    vec2 p = (UV - vec2(0.5)) * 2.0;
    float r = length(p);
    float rings = smoothstep(0.93, 1.0, sin(r * 60.0 - TIME * speed * 20.0) * 0.5 + 0.5);
    float fade = smoothstep(1.0, 0.1, r);
    float vignette = smoothstep(1.0, 0.25, r);
    vec3 col = base_color.rgb * (0.6 + 0.8 * vignette) + ring_color.rgb * rings * fade * 0.06;
    ALBEDO = col;
}
