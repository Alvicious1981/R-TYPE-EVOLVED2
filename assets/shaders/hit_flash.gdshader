shader_type canvas_item;

uniform bool hit_flash = false;

void fragment() {
	if (hit_flash) {
		COLOR = vec4(1.0, 1.0, 1.0, COLOR.a);
	}
}
