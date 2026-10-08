class_name DayCycle
extends RefCounted
## Tageszeit: Farbton der Welt, Nachtstärke für Lichter, Sonnenrichtung für Schatten.

const KEYS := [
	[0.0, Color(0.40, 0.44, 0.70)],
	[4.5, Color(0.42, 0.46, 0.72)],
	[6.0, Color(0.80, 0.62, 0.62)],
	[7.5, Color(1.00, 0.93, 0.86)],
	[10.0, Color(1.00, 1.00, 0.98)],
	[15.0, Color(1.00, 0.99, 0.94)],
	[17.5, Color(1.00, 0.88, 0.74)],
	[19.0, Color(0.92, 0.64, 0.56)],
	[20.5, Color(0.56, 0.52, 0.76)],
	[22.0, Color(0.42, 0.46, 0.72)],
	[24.0, Color(0.40, 0.44, 0.70)],
]


static func tint(hour: float) -> Color:
	var h := fposmod(hour, 24.0)
	for i in KEYS.size() - 1:
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if h >= a[0] and h <= b[0]:
			var t: float = (h - float(a[0])) / (float(b[0]) - float(a[0]))
			t = t * t * (3.0 - 2.0 * t)
			return (a[1] as Color).lerp(b[1], t)
	return Color.WHITE


## 0 am Tag, 1 in der Nacht. Lichter gehen in der Dämmerung an.
static func night(hour: float) -> float:
	var h := fposmod(hour, 24.0)
	if h >= 20.5 or h < 5.0:
		return 1.0
	if h >= 18.5:
		return smoothstep(18.5, 20.5, h)
	if h < 7.0:
		return 1.0 - smoothstep(5.0, 7.0, h)
	return 0.0


## Schattenrichtung pro Pixel Höhe. Morgens nach links, abends nach rechts,
## immer etwas zum Betrachter hin, damit der Schatten neben dem Gebäude sichtbar ist.
static func sun_vector(hour: float) -> Vector2:
	var h := clampf(fposmod(hour, 24.0), 6.0, 18.0)
	var t := (h - 6.0) / 12.0
	var x := lerpf(-0.85, 0.85, t)
	return Vector2(x, 0.16 + absf(x) * 0.22)


## Wie kräftig die Schatten sind. Nachts keine.
static func sun_strength(hour: float) -> float:
	var h := fposmod(hour, 24.0)
	if h < 6.0 or h > 19.0:
		return 0.0
	if h < 8.0:
		return smoothstep(6.0, 8.0, h)
	if h > 17.0:
		return 1.0 - smoothstep(17.0, 19.0, h)
	return 1.0


static func clock_text(hour: float) -> String:
	var h := fposmod(hour, 24.0)
	var hh := int(h)
	var mm := int((h - hh) * 60.0) / 10 * 10
	return "%02d:%02d" % [hh, mm]
