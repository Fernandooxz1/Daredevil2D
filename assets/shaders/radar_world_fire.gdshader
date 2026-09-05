shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform bool is_active = false;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fire_color : source_color = vec4(0.95, 0.18, 0.12, 1.0);
uniform vec3 edge_acoustic_color : source_color = vec3(0.92, 0.92, 0.96);
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.65;

void fragment() {
	vec4 scene_color = texture(screen_texture, SCREEN_UV);
	if (!is_active || intensity <= 0.001) {
		COLOR = scene_color;
	} else {
		vec3 base = scene_color.rgb;

		// 1. Muestreo de vecinos para deteccion de contornos/estructuras definidas (Edges)
		vec2 offset = SCREEN_PIXEL_SIZE * 1.5;
		vec3 col_up    = texture(screen_texture, SCREEN_UV + vec2(0.0, -offset.y)).rgb;
		vec3 col_down  = texture(screen_texture, SCREEN_UV + vec2(0.0, offset.y)).rgb;
		vec3 col_left  = texture(screen_texture, SCREEN_UV + vec2(-offset.x, 0.0)).rgb;
		vec3 col_right = texture(screen_texture, SCREEN_UV + vec2(offset.x, 0.0)).rgb;

		float diff = length(col_up - col_down) + length(col_left - col_right);
		float edge = smoothstep(0.06, 0.28, diff);

		// 2. Desaturacion selectiva estricta a Negro, Gris y Blanco
		float gray = dot(base, vec3(0.299, 0.587, 0.114));
		vec3 dark_mono = vec3(gray * 0.14);
		vec3 structural_view = dark_mono + edge_acoustic_color * (edge * 0.95);

		// 3. Luces brillantes no-rojas (como farolas): se convierten en blanco puro resplandeciente
		float brightness = max(gray, max(base.r, max(base.g, base.b)));
		float bright_light = smoothstep(0.42, 0.92, brightness);
		vec3 white_glow = vec3(clamp(brightness * 1.25, 0.0, 2.0));
		vec3 non_red_view = mix(structural_view, max(structural_view, white_glow), bright_light);

		// 4. Aislamiento exclusivo del color ROJO
		float red_diff = max(0.0, base.r - max(base.g, base.b));
		float is_red = smoothstep(0.06, 0.24, red_diff) * smoothstep(0.2, 0.5, base.r);

		// Para pixeles con rojo (traje Daredevil, siluetas ladrones, alerta '!', neones rojos),
		// aislar y potenciar canal rojo suprimiendo verde y azul:
		vec3 pure_red = vec3(base.r * 1.35, base.g * 0.08, base.b * 0.08);

		// Mezcla: cualquier elemento no-rojo en blanco/negro/gris vs rojo carmesi puro
		vec3 combat_view = mix(non_red_view, pure_red, is_red);

		// 5. Viñeta en negro y carbon profundo en los bordes para cerrar el plano
		vec2 uv = SCREEN_UV * (1.0 - SCREEN_UV.yx);
		float vignette = uv.x * uv.y * 15.0;
		vignette = clamp(pow(vignette, 0.28), 0.0, 1.0);
		float edge_fade = (1.0 - vignette) * vignette_strength;
		vec3 charcoal_black = vec3(0.012, 0.012, 0.015);
		combat_view = mix(combat_view, charcoal_black, edge_fade);

		// 6. Transicion suave segun intensity
		vec3 final_color = mix(base, combat_view, intensity);
		COLOR = vec4(final_color, scene_color.a);
	}
}
