shader_type canvas_item;

// Map (black and red) to (grey and yellow).

void fragment() {
	COLOR.rgb = COLOR.r * vec3(1.0, 0.95, 0.18);
	COLOR.rgb += (1.0 - COLOR.r) * vec3(0.3, 0.3, 0.3);
}
