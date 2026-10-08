shader_type canvas_item;
// Färbt die Welt nach Tageszeit. Leuchtende Teile nutzen dieses Material nicht.

uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
	COLOR.rgb *= tint.rgb;
}
