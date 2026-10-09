shader_type canvas_item;
// Verfall eines Gebäudes, Pixel für Pixel im Raster der Grafik.
// Alle Werte laufen von 0 bis 1: Moos, Ranken, Rost, Löcher im Dach, Einsturz, Schnee.
// Die Farben kommen aus der Palette, das Ergebnis bleibt Pixelkunst. Der Farbton der Welt wird am Ende angewendet.

uniform vec4 tint : source_color = vec4(1.0);
uniform float age = 0.0;
uniform float moss = 0.0;
uniform float vine = 0.0;
uniform float rust = 0.0;
uniform float holes = 0.0;
uniform float collapse = 0.0;
uniform float snow = 0.0;
uniform float seed = 1.0;

const vec3 MOSS_D = vec3(0.1490, 0.2157, 0.1725);
const vec3 MOSS = vec3(0.2392, 0.3333, 0.2157);
const vec3 GRASS = vec3(0.3569, 0.4549, 0.2588);
const vec3 GRASS_L = vec3(0.5176, 0.5804, 0.3529);
const vec3 LEAF_L = vec3(0.6784, 0.6980, 0.4627);
const vec3 RUST = vec3(0.6392, 0.3529, 0.1843);
const vec3 BRICK_D = vec3(0.4314, 0.2039, 0.2000);
const vec3 SOIL_D = vec3(0.2314, 0.1647, 0.1490);
const vec3 BONE = vec3(0.8471, 0.8235, 0.7529);
const vec3 WHITE = vec3(0.9373, 0.9137, 0.8549);
const vec3 BLACK = vec3(0.0784, 0.0706, 0.0941);

float hash(vec2 p) {
	return fract(sin(dot(p + vec2(seed, seed * 0.37), vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 size = vec2(textureSize(TEXTURE, 0));
	vec2 px = floor(UV * size);
	vec3 col = tex.rgb;
	float alpha = tex.a;
	if (alpha < 0.5) {
		COLOR = vec4(0.0);
	} else {
		float top = px.y / size.y;
		float up = size.y - px.y;

		// Einsturz: eine ausgefranste Linie wandert von oben nach unten
		float cut = collapse * size.y * 0.88 + (vnoise(vec2(px.x * 0.28, 4.0)) - 0.5) * 12.0 * collapse;
		if (collapse > 0.0 && px.y < cut) {
			alpha = 0.0;
		}
		// Löcher im Dach: Flecken im oberen Teil, ein dunkler Rand zeigt die Tiefe
		if (holes > 0.0 && top < 0.62) {
			float n = vnoise(px * 0.16 + vec2(9.0, 5.0)) * 0.75 + hash(floor(px * 0.5)) * 0.25;
			float lim = 1.0 - holes * 0.5;
			if (n > lim) {
				alpha = 0.0;
			} else if (n > lim - 0.05) {
				col = BLACK;
			}
		}
		if (alpha > 0.5) {
			// Alter: blasser und dunkler
			float luma = dot(col, vec3(0.3, 0.55, 0.15));
			col = mix(col, vec3(luma) * 0.9, age * 0.45);
			col *= 1.0 - age * 0.12;
			// Rost läuft in Streifen herunter
			if (rust > 0.0) {
				float streak = vnoise(vec2(px.x * 0.9, px.y * 0.07)) * 0.7 + hash(px) * 0.3;
				if (streak < rust * 0.38) {
					col = hash(px + 7.0) < 0.55 ? BRICK_D : RUST;
				}
			}
			// Moos wächst am Fuß und auf den Kanten
			if (moss > 0.0) {
				float bias = 0.35 + 0.65 * smoothstep(0.0, 0.7, 1.0 - up / size.y * 0.7);
				float m = hash(px + 3.0) * 0.55 + vnoise(px * 0.14) * 0.45;
				if (m < moss * bias * 0.75) {
					float k = hash(px + 11.0);
					col = k < 0.45 ? MOSS : (k < 0.8 ? MOSS_D : GRASS);
				}
			}
			// Ranken: Stränge klettern von unten die Wand hoch
			if (vine > 0.0) {
				float strand = hash(vec2(floor(px.x / 2.0), 7.0));
				float reach = vine * size.y * (0.2 + 0.8 * strand);
				if (up < reach) {
					float fade = 1.0 - up / max(reach, 1.0);
					float leaf = hash(px + 5.0);
					if (leaf < 0.5 + 0.48 * fade) {
						col = leaf < 0.14 ? LEAF_L : (leaf < 0.5 ? GRASS : MOSS);
						if (hash(px + 21.0) > 0.97) {
							col = BONE;
						}
					}
				}
			}
			// Schnee liegt auf allen Kanten, die nach oben zeigen
			if (snow > 0.0) {
				float above = texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y)).a;
				float above2 = texture(TEXTURE, UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y * 2.0)).a;
				if (above < 0.5 || (above2 < 0.5 && hash(px + 31.0) < 0.6)) {
					if (hash(px + 17.0) < snow) {
						col = hash(px + 19.0) < 0.3 ? BONE : WHITE;
					}
				}
			}
		}
		COLOR = vec4(col * tint.rgb, alpha);
	}
}
