shader_type canvas_item;
// Der Boden im Zeitraffer: Gras bricht durch die Straßen, Wasser sammelt sich in Senken, Schnee deckt alles zu.
// Alles wird pro Pixel im Raster des Bodenbildes entschieden. Der Farbton der Welt kommt am Ende.

uniform sampler2D road_mask : filter_nearest;
uniform sampler2D height_map : filter_linear;
uniform vec4 tint : source_color = vec4(1.0);
uniform float cover = 0.0;
uniform float water = 0.0;
uniform float snow = 0.0;
uniform float time = 0.0;

const vec3 MOSS_D = vec3(0.1490, 0.2157, 0.1725);
const vec3 MOSS = vec3(0.2392, 0.3333, 0.2157);
const vec3 GRASS = vec3(0.3569, 0.4549, 0.2588);
const vec3 GRASS_L = vec3(0.5176, 0.5804, 0.3529);
const vec3 SLATE = vec3(0.2275, 0.2314, 0.3098);
const vec3 TEAL = vec3(0.2314, 0.4000, 0.4392);
const vec3 WATER = vec3(0.3686, 0.5608, 0.5882);
const vec3 SKY = vec3(0.5765, 0.7176, 0.7059);
const vec3 SAND = vec3(0.8039, 0.6980, 0.4980);
const vec3 BONE = vec3(0.8471, 0.8235, 0.7529);
const vec3 WHITE = vec3(0.9373, 0.9137, 0.8549);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 size = vec2(textureSize(TEXTURE, 0));
	vec2 px = floor(UV * size);
	vec3 col = tex.rgb;

	// Gras auf Asphalt und Gehweg. Es beginnt in Rissen und wächst zu Flecken zusammen.
	if (cover > 0.0 && texture(road_mask, UV).r > 0.5) {
		float n = vnoise(px / 5.0) * 0.6 + hash(px) * 0.4;
		if (n < cover) {
			float k = hash(px + 3.0);
			col = k < 0.3 ? MOSS : (k < 0.75 ? GRASS : (k < 0.93 ? GRASS_L : MOSS_D));
		} else if (n < cover + 0.05) {
			col = SLATE;
		}
	}

	// Wasser steht in den Senken. Ein heller Saum liegt am Rand, die Mitte glitzert.
	if (water > 0.0) {
		float h = texture(height_map, UV).r + (vnoise(px / 3.0) - 0.5) * 0.045;
		float d = water - h;
		if (d > 0.0) {
			if (d < 0.012) {
				col = hash(px + 5.0) < 0.5 ? SAND : GRASS_L;
			} else if (d < 0.03) {
				col = hash(px + 9.0) < 0.5 ? WATER : SKY;
			} else {
				col = d > 0.07 ? TEAL : WATER;
				float s = sin(time * 1.3 + hash(floor(px / 3.0)) * 6.28);
				if (s > 0.9 && hash(px + 13.0) > 0.6) {
					col = SKY;
				}
			}
		}
	}

	// Schnee
	if (snow > 0.0) {
		float n = vnoise(px / 4.0) * 0.7 + hash(px + 2.0) * 0.3;
		if (n < snow) {
			col = hash(px + 4.0) < 0.25 ? BONE : WHITE;
		}
	}
	COLOR = vec4(col * tint.rgb, 1.0);
}
