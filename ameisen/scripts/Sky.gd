extends Node2D
## Zeichnet Himmel, Sonne, Wolken, Bäume, Büsche, Gras, Blumen und den Sandhügel.

var world
var main
var dirty := true

var _stalks: Array = []     # [x, höhe, neigung, blüte, farbe]
var _tufts: Array = []
var _stars: Array = []
var _clouds: Array = []
var _seed := -1
var _redraw_t := 0.0
var _clock := 0.0

const SKY_TOP := Color(0.60, 0.78, 0.92)
const SKY_LOW := Color(0.86, 0.93, 0.95)
const TRUNK := Color(0.47, 0.31, 0.19)
const TRUNK_DARK := Color(0.33, 0.21, 0.12)
const LEAF := [Color(0.36, 0.58, 0.30), Color(0.47, 0.68, 0.36), Color(0.28, 0.48, 0.25)]
const LEAF_LIGHT := Color(0.62, 0.79, 0.47)
const FRUIT := Color(0.86, 0.22, 0.16)
const FRUIT_LIGHT := Color(1.0, 0.55, 0.45)
const SAND := Color(0.88, 0.77, 0.55)
const SAND_DARK := Color(0.78, 0.66, 0.45)


func _generate() -> void:
	_seed = world.seed_value
	var r := RandomNumberGenerator.new()
	r.seed = _seed + 99
	_stalks.clear()
	_tufts.clear()
	_stars.clear()
	_clouds.clear()
	var wpx: int = World.W * World.T
	for k in 70:
		var x := r.randi_range(1, wpx - 2)
		if absi(x - World.ENT * World.T) < 30 and r.randf() < 0.7:
			continue
		var bloom := 0
		var q := r.randf()
		if q < 0.35:
			bloom = 1     # gelber Kopf
		elif q < 0.5:
			bloom = 2     # gelbe Blüte mit Blättern
		_stalks.append([x, r.randi_range(6, 30), r.randf_range(-0.12, 0.12), bloom, r.randi_range(0, 2)])
	for k in 140:
		_tufts.append([r.randi_range(0, wpx - 1), r.randi_range(1, 4), r.randi_range(0, 2)])
	for k in 40:
		_stars.append(Vector2(r.randi_range(2, wpx - 3), r.randi_range(2, 90)))
	for k in 5:
		_clouds.append([r.randf_range(0, wpx), r.randi_range(6, 40), r.randi_range(10, 22), r.randf_range(1.0, 2.5)])


func tick(dt: float) -> void:
	_clock += dt
	_redraw_t -= dt
	if dirty or _redraw_t <= 0.0:
		_redraw_t = 0.25
		dirty = false
		queue_redraw()


func _draw() -> void:
	if world == null:
		return
	if _seed != world.seed_value:
		_generate()
	var ev = main.events
	var wpx: float = World.W * World.T
	var gy: float = World.G * World.T
	var light: float = ev.daylight()
	var rain: bool = ev.raining
	# Himmel als Farbbänder
	var bands := 16
	for b in bands:
		var t := float(b) / (bands - 1)
		var c := SKY_TOP.lerp(SKY_LOW, t)
		if rain:
			c = c.lerp(Color(0.55, 0.6, 0.65), 0.55)
		draw_rect(Rect2(0, b * gy / bands, wpx, gy / bands + 1), c)
	# Sterne in der Nacht
	if light < 0.45:
		var a := clampf((0.45 - light) * 3.0, 0.0, 1.0)
		for s in _stars:
			var tw: float = 0.6 + 0.4 * sin(_clock * 2.0 + s.x)
			draw_rect(Rect2(s, Vector2.ONE), Color(1, 1, 0.9, a * tw))
	_draw_sun_moon(ev, wpx)
	_draw_clouds(wpx, rain)
	for s in world.sources:
		if s.kind == 0:
			_draw_tree(s)
	for st in _stalks:
		_draw_stalk(st, gy)
	for s in world.sources:
		if s.kind == 1:
			_draw_bush(s)
	_draw_mound(gy)
	for tf in _tufts:
		var c: Color = LEAF[tf[2]]
		draw_rect(Rect2(tf[0], gy - tf[1], 1, tf[1]), c)
	draw_rect(Rect2(0, gy - 1, wpx, 1), Color(0.40, 0.62, 0.30))


func _draw_sun_moon(ev, wpx: float) -> void:
	var t: float = ev.time_of_day
	var day_t := (t - 0.22) / 0.56
	if day_t > 0.0 and day_t < 1.0:
		var p := Vector2(lerpf(18.0, wpx - 18.0, day_t), 34.0 - sin(day_t * PI) * 22.0)
		for k in 3:
			draw_circle(p, 11.0 - k * 2.0, Color(1.0, 0.93, 0.6, 0.12 + k * 0.05))
		draw_circle(p, 6.0, Color(1.0, 0.92, 0.55))
		draw_circle(p + Vector2(-1, -1), 4.0, Color(1.0, 0.97, 0.78))
	var nt := fposmod(t + 0.5, 1.0)
	var night_t := (nt - 0.22) / 0.56
	if night_t > 0.0 and night_t < 1.0:
		var m := Vector2(lerpf(18.0, wpx - 18.0, night_t), 30.0 - sin(night_t * PI) * 18.0)
		draw_circle(m, 5.0, Color(0.95, 0.95, 0.85))
		draw_circle(m + Vector2(2, -1), 4.0, SKY_TOP.darkened(0.6))


func _draw_clouds(wpx: float, rain: bool) -> void:
	for c in _clouds:
		var x: float = fposmod(c[0] + _clock * c[3], wpx + 60.0) - 30.0
		var y: float = c[1]
		var w: float = c[2]
		var col := Color(0.97, 0.98, 1.0) if not rain else Color(0.55, 0.58, 0.62)
		var shade := col.darkened(0.12)
		draw_rect(Rect2(x, y + 2, w, 3), shade)
		draw_rect(Rect2(x + 2, y, w - 5, 3), col)
		draw_rect(Rect2(x + w * 0.3, y - 2, w * 0.4, 3), col)


func _draw_tree(s: Dictionary) -> void:
	var T := World.T
	var tx: float = s.trunk * T + 1
	var top: float = s.cy * T
	var gy: float = World.G * T
	draw_rect(Rect2(tx - 1, top, 4, gy - top), TRUNK)
	draw_rect(Rect2(tx + 2, top, 1, gy - top), TRUNK_DARK)
	draw_rect(Rect2(tx - 2, gy - 3, 6, 3), TRUNK)
	var c := Vector2(s.cx * T + 1.5, s.cy * T)
	for b in s.blobs:
		var p: Vector2 = c + Vector2(b[0], b[1]) * T
		_blob(p, b[2] * T, LEAF[b[3]])
	for b in s.blobs:
		var p2: Vector2 = c + Vector2(b[0], b[1]) * T
		draw_rect(Rect2(p2 + Vector2(-b[2], -b[2]) * T * 0.45, Vector2(3, 2)), LEAF_LIGHT)
	_draw_fruits(s)


func _draw_bush(s: Dictionary) -> void:
	var T := World.T
	var c := Vector2(s.cx * T + 1.5, (World.SURF - 2) * T)
	for b in s.blobs:
		_blob(c + Vector2(b[0], b[1]) * T, b[2] * T, LEAF[b[3]])
	_draw_fruits(s)


func _blob(p: Vector2, r: float, col: Color) -> void:
	# kantige Blätterwolke aus Rechtecken für Pixel-Optik
	var rr := int(r)
	for dy in range(-rr, rr + 1, 2):
		var hw := int(sqrt(maxf(r * r - dy * dy, 0.0)))
		draw_rect(Rect2(floorf(p.x) - hw, floorf(p.y) + dy, hw * 2, 2), col)
	draw_rect(Rect2(floorf(p.x) - rr * 0.5, floorf(p.y) + rr * 0.5, rr, 2), col.darkened(0.15))


func _draw_fruits(s: Dictionary) -> void:
	var T := World.T
	for f in s.fruits:
		if not f.alive:
			continue
		var p := Vector2(f.x * T, f.y * T)
		draw_rect(Rect2(p, Vector2(3, 3)), FRUIT)
		draw_rect(Rect2(p, Vector2(1, 1)), FRUIT_LIGHT)
		draw_rect(Rect2(p + Vector2(1, -1), Vector2(1, 1)), TRUNK_DARK)


func _draw_stalk(st: Array, gy: float) -> void:
	var x: float = st[0]
	var h: int = st[1]
	var lean: float = st[2] + sin(_clock * 0.8 + x * 0.3) * 0.04
	var col: Color = LEAF[st[4]]
	for k in h:
		draw_rect(Rect2(floorf(x + lean * k), gy - 1 - k, 1, 1), col)
	var top := Vector2(floorf(x + lean * h), gy - 1 - h)
	if h > 10:
		draw_rect(Rect2(floorf(x + lean * h * 0.5) - 2, gy - h * 0.5, 2, 1), col)
	match st[3]:
		1:
			draw_rect(Rect2(top + Vector2(-1, -3), Vector2(2, 4)), Color(0.93, 0.76, 0.22))
			draw_rect(Rect2(top + Vector2(-1, -3), Vector2(1, 1)), Color(1.0, 0.92, 0.5))
		2:
			var y := Color(0.98, 0.85, 0.3)
			draw_rect(Rect2(top + Vector2(-1, -2), Vector2(3, 3)), y)
			draw_rect(Rect2(top + Vector2(-2, -1), Vector2(5, 1)), y)
			draw_rect(Rect2(top + Vector2(0, -3), Vector2(1, 5)), y)
			draw_rect(Rect2(top + Vector2(0, -1), Vector2(1, 1)), Color(0.85, 0.55, 0.15))


func _draw_mound(gy: float) -> void:
	var T := World.T
	for x in World.W:
		var h: float = world.mound[x]
		if h < 0.4:
			continue
		var hp := ceilf(h)
		draw_rect(Rect2(x * T, gy - hp, T, hp), SAND)
		draw_rect(Rect2(x * T, gy - hp, T, 1), SAND.lightened(0.15))
		# Dither für Körnung
		for k in int(hp / 3.0):
			if World.hash2(x, k) % 3 == 0:
				draw_rect(Rect2(x * T + (k % 3), gy - hp + 2 + k * 3, 1, 1), SAND_DARK)
