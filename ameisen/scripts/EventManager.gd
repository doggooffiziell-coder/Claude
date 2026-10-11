extends Node2D
## Tag und Nacht, Fluten mit Regen und Tausendfüßler-Angriffe.

const DAY_LENGTH := 300.0          # Sekunden für einen ganzen Tag
const RAIN_TIME := 20.0
const CENT_SEGMENTS := 12
const CENT_SPACING := 3.0
const NIGHT_COLOR := Color(0.36, 0.40, 0.62)
const DUSK_COLOR := Color(1.0, 0.78, 0.6)

var main
var rng := RandomNumberGenerator.new()
var time_of_day := 0.3             # 0 = Mitternacht, 0.5 = Mittag
var day := 1

var raining := false
var _rain_t := 0.0
var _next_flood := 0.0
var _drops: Array = []

var cent_active := false
var cent_fleeing := false
var cent_head := Vector2.ZERO
var cent_hp := 0.0
var _cent_angle := 0.0
var _cent_life := 0.0
var _cent_segs := PackedVector2Array()
var _next_cent := 0.0
var _eat_cd := 0.0
var _target := Vector2.ZERO
var _target_t := 0.0
var _walk := 0.0


func setup(m) -> void:
	main = m
	rng.randomize()
	reset()


func reset() -> void:
	raining = false
	cent_active = false
	_drops.clear()
	_next_flood = rng.randf_range(300.0, 450.0)
	_next_cent = rng.randf_range(200.0, 320.0)
	queue_redraw()


# ---------------------------------------------------------------- Tag und Nacht

func daylight() -> float:
	return clampf(0.5 - 0.5 * cos(time_of_day * TAU), 0.0, 1.0)


func is_night() -> bool:
	return daylight() < 0.2


func _update_light() -> void:
	var l := smoothstep(0.0, 0.6, daylight())
	var c := NIGHT_COLOR.lerp(Color.WHITE, l)
	var dusk := 1.0 - absf(l - 0.5) * 2.0
	c = c.lerp(DUSK_COLOR, dusk * 0.22)
	if raining:
		c = c.darkened(0.12)
	main.day_night.color = c


# ---------------------------------------------------------------- Takt

func tick(dt: float) -> void:
	time_of_day += dt / DAY_LENGTH
	if time_of_day >= 1.0:
		time_of_day -= 1.0
		day += 1
	_update_light()
	_tick_flood(dt)
	_tick_centipede(dt)
	if raining or cent_active or not _drops.is_empty():
		queue_redraw()


func _tick_flood(dt: float) -> void:
	if not raining:
		_next_flood -= dt
		if _next_flood <= 0.0 and main.world.cells.count(World.TUNNEL) > 220:
			start_flood()
		return
	_rain_t -= dt
	main.world.add_rain(0.015, rng)
	var wpx := float(World.W * World.T)
	var gy := float(World.G * World.T)
	while _drops.size() < 70:
		_drops.append(Vector2(rng.randf_range(0, wpx), rng.randf_range(-gy, 0)))
	for k in _drops.size():
		var d: Vector2 = _drops[k]
		d.y += 170.0 * dt
		d.x -= 20.0 * dt
		if d.y > gy - 2.0:
			d = Vector2(rng.randf_range(0, wpx + 20.0), rng.randf_range(-20.0, 0.0))
		_drops[k] = d
	if _rain_t <= 0.0:
		raining = false
		_drops.clear()
		_next_flood = rng.randf_range(220.0, 420.0)


func start_flood() -> void:
	raining = true
	_rain_t = RAIN_TIME
	main.hud.banner("FLUT! REGEN LÄUFT INS NEST", 4.0)


func start_centipede() -> void:
	cent_active = true
	cent_fleeing = false
	cent_hp = 24.0
	_cent_life = 0.0
	_eat_cd = 1.0
	var left := rng.randf() < 0.5
	var y := rng.randf_range((World.G + 12) * World.T, (World.H - 10) * World.T)
	cent_head = Vector2(-12.0 if left else World.W * World.T + 12.0, y)
	_cent_angle = 0.0 if left else PI
	_cent_segs.resize(CENT_SEGMENTS)
	for k in CENT_SEGMENTS:
		_cent_segs[k] = cent_head - Vector2.from_angle(_cent_angle) * CENT_SPACING * k
	_target = Vector2(World.ENT * World.T, (World.G + 20) * World.T)
	main.hud.banner("TAUSENDFÜSSLER!", 4.0)


func _tick_centipede(dt: float) -> void:
	if not cent_active:
		_next_cent -= dt
		if _next_cent <= 0.0 and main.ants.count >= 25:
			start_centipede()
		return
	_cent_life += dt
	_walk += dt
	var ants = main.ants
	var wpx := float(World.W * World.T)
	var top := float(World.G * World.T + 4)
	var bottom := float(World.H * World.T - 4)
	if not cent_fleeing and (cent_hp <= 0.0 or _cent_life > 40.0):
		cent_fleeing = true
		if cent_hp <= 0.0:
			main.hud.banner("SOLDATEN VERJAGEN DEN TAUSENDFÜSSLER", 4.0)
	# Ziel wählen: nächste Ameise unter der Erde
	_target_t -= dt
	if cent_fleeing:
		_target = Vector2(-40.0 if cent_head.x < wpx * 0.5 else wpx + 40.0, cent_head.y)
	elif _target_t <= 0.0:
		_target_t = 0.6
		var best := 1.0e9
		for i in ants.count:
			if ants.role[i] == Ant.R_QUEEN or ants.cy[i] < World.G:
				continue
			var d: float = cent_head.distance_squared_to(Vector2(ants.px[i], ants.py[i]))
			if d < best:
				best = d
				_target = Vector2(ants.px[i], ants.py[i])
	# lenken
	var want := cent_head.angle_to_point(_target)
	var diff := wrapf(want - _cent_angle, -PI, PI)
	_cent_angle += clampf(diff, -2.2 * dt, 2.2 * dt) + sin(_walk * 3.0) * 0.6 * dt
	var speed := 24.0 if cent_fleeing else 13.0
	cent_head += Vector2.from_angle(_cent_angle) * speed * dt
	if cent_head.y < top:
		cent_head.y = top
		_cent_angle = absf(_cent_angle)
	if cent_head.y > bottom:
		cent_head.y = bottom
		_cent_angle = -absf(_cent_angle)
	# Segmente folgen dem Kopf
	_cent_segs[0] = cent_head
	for k in range(1, CENT_SEGMENTS):
		var a := _cent_segs[k - 1]
		var b := _cent_segs[k]
		if a.distance_to(b) > CENT_SPACING:
			_cent_segs[k] = a + (b - a).normalized() * CENT_SPACING
	# fressen und kämpfen
	_eat_cd -= dt
	if not cent_fleeing:
		for i in ants.count:
			var p := Vector2(ants.px[i], ants.py[i])
			var d := p.distance_to(cent_head)
			if d > 7.0:
				continue
			if ants.role[i] == Ant.R_SOLDIER:
				cent_hp -= 2.6 * dt
			elif d < 4.5:
				cent_hp -= 0.35 * dt
				if _eat_cd <= 0.0 and ants.role[i] != Ant.R_QUEEN:
					ants.request_kill(i, false)
					_eat_cd = 3.0
	if cent_fleeing and (cent_head.x < -30.0 or cent_head.x > wpx + 30.0):
		cent_active = false
		_next_cent = rng.randf_range(150.0, 300.0)
		queue_redraw()


# ---------------------------------------------------------------- Zeichnen

func _draw() -> void:
	for d in _drops:
		draw_rect(Rect2(d, Vector2(1, 3)), Color(0.7, 0.82, 0.98, 0.7))
	if cent_active:
		_draw_centipede()


func _draw_centipede() -> void:
	var body := Color(0.55, 0.20, 0.12)
	var body2 := Color(0.42, 0.14, 0.09)
	var leg := Color(0.30, 0.12, 0.08)
	for k in range(CENT_SEGMENTS - 1, -1, -1):
		var p := _cent_segs[k].floor()
		var nxt := _cent_segs[maxi(k - 1, 0)]
		var fwd := (nxt - _cent_segs[k]).normalized() if k > 0 else Vector2.from_angle(_cent_angle)
		var side := Vector2(-fwd.y, fwd.x)
		var swing := sin(_walk * 14.0 + k * 1.3) * 1.2
		draw_line(p + side * 1.5, p + side * 3.5 + fwd * swing, leg, 1.0)
		draw_line(p - side * 1.5, p - side * 3.5 - fwd * swing, leg, 1.0)
		var c := body if k % 2 == 0 else body2
		if k == 0:
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(5, 4)), Color(0.3, 0.1, 0.06))
			draw_line(p + fwd * 2.0 + side, p + fwd * 6.0 + side * 3.0, leg, 1.0)
			draw_line(p + fwd * 2.0 - side, p + fwd * 6.0 - side * 3.0, leg, 1.0)
			draw_rect(Rect2(p + fwd * 2.0 - Vector2(0.5, 0.5), Vector2(1, 1)), Color(0.9, 0.8, 0.3))
		else:
			draw_rect(Rect2(p - Vector2(2, 1), Vector2(4, 3)), c)
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 1)), c.lightened(0.25))


# ---------------------------------------------------------------- Speichern

func to_dict() -> Dictionary:
	return {"time": time_of_day, "day": day, "next_flood": _next_flood, "next_cent": _next_cent}


func from_dict(d: Dictionary) -> void:
	reset()
	time_of_day = float(d.get("time", 0.3))
	day = int(d.get("day", 1))
	_next_flood = float(d.get("next_flood", _next_flood))
	_next_cent = float(d.get("next_cent", _next_cent))
