shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.9, 0.95, 1.0, 0.95);
uniform float outline_width : hint_range(0.0, 10.0) = 1.6;
uniform bool radar_highlight = false;
uniform vec4 radar_outline_color : source_color = vec4(3.5, 0.2, 0.15, 1.0);
uniform vec4 radar_tint_color : source_color = vec4(1.8, 0.15, 0.1, 1.0);
uniform float base_brightness : hint_range(0.5, 3.0) = 1.25;

// Hit Flash (Destello blanco puro al recibir impacto)
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hit_flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec4 node_mod = COLOR;

	if (col.a <= 0.1) {
		vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
		float max_a = 0.0;
		max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, -size.y)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, size.y)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(-size.x, 0.0)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(size.x, 0.0)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(-size.x, -size.y)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(size.x, -size.y)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(-size.x, size.y)).a);
		max_a = max(max_a, texture(TEXTURE, UV + vec2(size.x, size.y)).a);

		if (max_a > 0.1) {
			vec4 oc = radar_highlight ? radar_outline_color : outline_color;
			COLOR = vec4(oc.rgb * node_mod.rgb, max_a * oc.a * node_mod.a);
		} else {
			COLOR = vec4(0.0);
		}
	} else {
		if (radar_highlight) {
			// Silueta interna en escala de grises (negro / gris) con realce rojo carmesi puro
			float enemy_gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
			vec3 mono_body = vec3(enemy_gray * 0.38);
			vec3 red_accent = radar_tint_color.rgb * 0.4;
			vec3 high_col = mono_body + red_accent;
			COLOR = vec4(high_col * 1.5 * node_mod.rgb, col.a * node_mod.a);
		} else {
			COLOR = vec4(col.rgb * base_brightness * node_mod.rgb, col.a * node_mod.a);
		}
	}

	// Destello de impacto blanco puro
	if (hit_flash > 0.0 && COLOR.a > 0.01) {
		COLOR.rgb = mix(COLOR.rgb, hit_flash_color.rgb, hit_flash);
	}
}
