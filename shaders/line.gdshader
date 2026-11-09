shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
// Thin glowing orbit line.

uniform vec4 color : source_color = vec4(0.4, 0.4, 1.0, 1.0);
uniform float strength = 1.0;

void fragment() {
    ALBEDO = color.rgb * strength;
    ALPHA = 1.0;
}
