class_name VehicleArt
extends RefCounted
## Kleine Autos als isometrische Kisten. Richtung im Bodenraum:
## 0 = +U (rechts unten), 1 = +V (links unten), 2 = -U (links oben), 3 = -V (rechts oben).

static var _cache := {}

const LEN := 0.42
const WID := 0.22


static func car(dir: int, body: Color) -> Dictionary:
	var key := "%d_%s" % [dir, body.to_html()]
	if _cache.has(key):
		return _cache[key]
	var p := IsoPainter.new()
	p.c = PixelCanvas.new(34, 26)
	p.g = PixelCanvas.new(34, 26)
	p.origin = Vector2(17, 4)
	var along_u := dir == 0 or dir == 2
	var lu := LEN if along_u else WID
	var lv := WID if along_u else LEN
	var u0 := 0.5 - lu * 0.5
	var v0 := 0.5 - lv * 0.5
	var lt := Shade.light(body)
	var dk := Shade.dark(body)
	# Räder
	for f in [0.2, 0.8]:
		for side in [0.0, 1.0]:
			var wu: float = u0 + (lu * f if along_u else lu * side)
			var wv: float = v0 + (lv * side if along_u else lv * f)
			var wp := p.P(wu, wv, 1)
			p.c.rect(int(wp.x) - 1, int(wp.y) - 1, 2, 2, Pal.BLACK)
	# Karosserie
	p.box(u0, v0, u0 + lu, v0 + lv, 2, 6, body, dk, lt)
	# Kabine, nach hinten versetzt
	var cu0 := u0 + (lu * 0.25 if along_u else 0.02)
	var cu1 := u0 + (lu * 0.72 if along_u else lu - 0.02)
	var cv0 := v0 + (0.02 if along_u else lv * 0.25)
	var cv1 := v0 + (lv - 0.02 if along_u else lv * 0.72)
	p.wall_left(cu0, cu1, cv1, 6, 10, func(s, t, _x, _y): return Pal.BLUE_D if t < 0.75 else Pal.SKY)
	p.wall_right(cu1, cv0, cv1, 6, 10, func(s, t, _x, _y): return Pal.NIGHT if t < 0.75 else Pal.BLUE)
	p.ground(cu0, cv0, cu1, cv1, 10, func(_s, _t, _x, _y): return lt)
	# Lichter vorne und hinten
	var front := Vector3()
	var back := Vector3()
	match dir:
		0:
			front = Vector3(u0 + lu, v0 + lv * 0.5, 4)
			back = Vector3(u0, v0 + lv * 0.5, 4)
		1:
			front = Vector3(u0 + lu * 0.5, v0 + lv, 4)
			back = Vector3(u0 + lu * 0.5, v0, 4)
		2:
			front = Vector3(u0, v0 + lv * 0.5, 4)
			back = Vector3(u0 + lu, v0 + lv * 0.5, 4)
		_:
			front = Vector3(u0 + lu * 0.5, v0, 4)
			back = Vector3(u0 + lu * 0.5, v0 + lv, 4)
	var fp := p.P(front.x, front.y, front.z)
	var bp := p.P(back.x, back.y, back.z)
	# Nur sichtbare Seiten bekommen Lichter
	if dir == 0 or dir == 1:
		p.c.px(int(fp.x), int(fp.y), Pal.YELLOW)
	else:
		p.c.px(int(bp.x), int(bp.y), Pal.BRICK_L)
	p.c.outline(Pal.BLACK)
	var res := {"tex": p.c.texture(), "size": Vector2i(p.c.w, p.c.h), "anchor": p.P(0.5, 0.5, 0), "front": fp, "back": bp}
	_cache[key] = res
	return res
