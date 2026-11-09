shader_type spatial;
render_mode cull_back, blend_mix;
// Generic neon material: dark metallic body with an emissive fresnel rim.
// Used for obstacles, crystals and the core rings.

uniform vec4 color : source_color = vec4(1.0, 0.3, 0.37, 1.0);
uniform vec4 body_color : source_color = vec4(0.07, 0.04, 0.08, 1.0);
uniform float base_glow = 0.35;
uniform float rim_strength = 2.2;
uniform float rim_power = 2.0;
uniform float alpha = 1.0;
uniform float appear = 1.0;      // 0..1 spawn fade-in
uniform float flash = 0.0;       // 0..1 hit / pickup flash
uniform float shimmer = 0.0;     // >0 adds an animated stripe (moving obstacles)

void fragment() {
    float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
    float stripe = shimmer * (0.5 + 0.5 * sin(UV.x * 40.0 + TIME * 6.0));
    ALBEDO = body_color.rgb;
    METALLIC = 0.6;
    ROUGHNESS = 0.35;
    EMISSION = color.rgb * (base_glow + fres * rim_strength + stripe * 0.6) + vec3(flash);
    ALPHA = alpha * appear;
}
