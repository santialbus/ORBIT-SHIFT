shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
// Camera-facing radial glow (player halo, pickup flares).

uniform vec4 color : source_color = vec4(0.1, 0.9, 1.0, 1.0);
uniform float strength = 1.0;

void vertex() {
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
        INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
    MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
        vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
        vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
        vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
        vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
    float d = length(UV - vec2(0.5)) * 2.0;
    float a = pow(clamp(1.0 - d, 0.0, 1.0), 2.2);
    ALBEDO = color.rgb * strength;
    ALPHA = a;
}
