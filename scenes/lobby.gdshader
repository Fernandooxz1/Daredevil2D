shader_type canvas_item;

uniform vec4 fog_color = vec4(0.8, 0.5, 0.5, 0.1); // Rojo suave para el estilo Daredevil
uniform float speed_x = 0.0005; 
uniform float speed_y = 0.0005;
uniform float density = 1.0;

float noise(vec2 coord) {
    return fract(sin(dot(coord, vec2(12.9898, 78.233))) * 43758.5453);
}

float fog_pattern(vec2 coord) {
    vec2 p = coord * density;
    float n = noise(p);
    n += noise(p + vec2(5, 0.1)) * 0.1;
    return n / 1.5;
}

void fragment() {
    vec2 moving_coord = FRAGCOORD.xy + vec2(speed_x, speed_y) * TIME;
    float fog_val = fog_pattern(moving_coord * 0.01);
    float alpha = smoothstep(0.9, 0.1, fog_val) * fog_color.a;
    COLOR = vec4(fog_color.rgb, alpha);
}