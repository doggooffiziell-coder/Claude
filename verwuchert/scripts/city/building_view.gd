class_name BuildingView
extends Node2D
## Ein Gebäude in der Welt. Zeigt Baustelle, Gerüst mit Arbeitern, fertiges Haus und nachts Licht.
## Die Position liegt unten links auf den Feldern, damit die Y-Sortierung stimmt.

const T := 32

var data: Dictionary
var art: Dictionary
var builder: Node
var status := {}
var pop := 0.0
var glow: Node2D
var _smoke_t := 0.0
var _last_state := ""


func setup(b: Dictionary, city_builder: Node) -> void:
	data = b
	builder = city_builder
	art = SpriteFactory.building_for(b)
	position = Vector2(int(b.x) * T, (int(b.y) + int(b.h)) * T)
	use_parent_material = true
	glow = Node2D.new()
	glow.set_script(preload("res://scripts/city/glow_view.gd"))
	add_child(glow)
	glow.setup(self)
	_last_state = b.state


func footprint() -> Rect2:
	return Rect2(int(data.x) * T, int(data.y) * T, int(data.w) * T, int(data.h) * T)


func is_done() -> bool:
	return data.state == "done"


func _process(delta: float) -> void:
	if data.state != _last_state:
		if data.state == "done":
			pop = 1.0
		_last_state = data.state
	if pop > 0.0:
		pop = maxf(0.0, pop - delta * 4.0)
	var spd: float = builder.speed if builder else 1.0
	if data.state == "done" and spd > 0.0:
		_smoke_t -= delta * spd
		if _smoke_t <= 0.0:
			_emit_smoke()
	elif data.state == "building" and spd > 0.0:
		if randf() < delta * 3.0 * spd:
			var p := Vector2(randf_range(4, int(data.w) * T - 4), -randf_range(0, 6))
			builder.particles.emit("dust", global_position + p, 2)
	queue_redraw()


func _emit_smoke() -> void:
	var smoke: Array = art.get("smoke", [])
	if smoke.is_empty():
		_smoke_t = 99.0
		return
	var origin := global_position - Vector2(0, art.size.y)
	match data.type:
		"house":
			_smoke_t = randf_range(0.9, 1.6)
			if status.get("occupied", false) and randf() < 0.85:
				builder.particles.emit("smoke", origin + smoke[0], 1, {"size": 0.7, "life": 0.8})
		"factory":
			_smoke_t = randf_range(0.18, 0.3)
			if status.get("active", false):
				builder.particles.emit("smoke", origin + smoke[0], 1, {"size": 1.4, "dark": true, "life": 1.3})
		"power_plant":
			_smoke_t = randf_range(0.12, 0.2)
			builder.particles.emit("steam", origin + smoke[0], 1)
		_:
			_smoke_t = 1.0


func _draw() -> void:
	var size: Vector2i = art.size
	var origin := Vector2(0, -size.y)
	var fw := int(data.w) * T
	var fh := int(data.h) * T
	match data.state:
		"queued":
			_draw_site(fw, fh, false)
		"building":
			_draw_site(fw, fh, true)
			var p: float = clampf(float(data.progress), 0.0, 1.0)
			var vis := int(round(lerpf(4.0, float(size.y), p * p * (3.0 - 2.0 * p))))
			var src := Rect2(0, size.y - vis, size.x, vis)
			draw_texture_rect_region(art.tex, Rect2(0, -vis, size.x, vis), src)
			_draw_scaffold(fw, vis, p)
		_:
			if pop > 0.0:
				var s := 1.0 + sin(pop * PI) * 0.08
				var sy := 1.0 - sin(pop * PI) * 0.06 + (s - 1.0)
				var sx := 1.0 + sin(pop * PI) * 0.05
				draw_set_transform(Vector2(fw * 0.5 * (1.0 - sx), 0), 0.0, Vector2(sx, sy))
			draw_texture(art.tex, origin)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Baugrund: abgesteckte Fläche mit Pflöcken und Absperrband.
func _draw_site(fw: int, fh: int, started: bool) -> void:
	var r := Rect2(2, -fh + 2, fw - 4, fh - 4)
	draw_rect(r, Pal.a(Pal.SOIL, 0.85 if started else 0.45))
	if started:
		draw_rect(Rect2(r.position + Vector2(2, 2), r.size - Vector2(4, 4)), Pal.a(Pal.STONE_L, 0.9))
		draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 1)), Pal.BONE)
	# Pflöcke
	for p in [r.position, r.position + Vector2(r.size.x - 1, 0), r.position + Vector2(0, r.size.y - 1), r.end - Vector2.ONE]:
		draw_rect(Rect2(p + Vector2(0, -3), Vector2(1, 4)), Pal.WOOD_L)
		draw_rect(Rect2(p + Vector2(0, -3), Vector2(1, 1)), Pal.BRICK_L)
	# Absperrband rot-weiß
	var x := r.position.x
	while x < r.end.x:
		var col := Pal.BRICK_L if int(x / 3) % 2 == 0 else Pal.WHITE
		draw_rect(Rect2(x, r.position.y - 2, 1, 1), col)
		draw_rect(Rect2(x, r.end.y - 2, 1, 1), col)
		x += 1
	if not started:
		var t: float = builder.anim_time if builder else 0.0
		var bob := roundf(sin(t * 3.0) * 1.0)
		var icon := IconArt.get_icon("hourglass")
		draw_texture(icon, Vector2(fw * 0.5 - 4, -fh * 0.5 - 6 + bob))


## Gerüst aus Holz mit zwei Arbeitern, die hämmern und laufen.
func _draw_scaffold(fw: int, vis: int, p: float) -> void:
	var top := -vis - 3
	var poles := [3, fw - 4]
	if fw > 40:
		poles.append(fw / 2)
	for px_ in poles:
		draw_rect(Rect2(px_, top, 1, vis + 3), Pal.WOOD)
		draw_rect(Rect2(px_ + 1, top, 1, vis + 3), Pal.SOIL)
	var y := -6
	while y > top:
		draw_rect(Rect2(2, y, fw - 4, 1), Pal.WOOD_L)
		draw_rect(Rect2(2, y + 1, fw - 4, 1), Pal.SOIL)
		y -= 9
	draw_rect(Rect2(1, top, fw - 2, 1), Pal.WOOD_L)
	# Kran-Haken bei großen Gebäuden
	if fw > 40:
		draw_rect(Rect2(fw - 10, top - 18, 1, 18), Pal.OCHRE)
		draw_rect(Rect2(fw - 26, top - 18, 22, 1), Pal.OCHRE)
		var t0: float = builder.anim_time if builder else 0.0
		var hook_y := top - 14 + roundf(sin(t0 * 1.5) * 3.0) + 4
		draw_rect(Rect2(fw - 22, top - 17, 1, hook_y - (top - 17)), Pal.STONE_L)
		draw_rect(Rect2(fw - 24, hook_y, 4, 2), Pal.STONE_D)
	# Arbeiter
	var t: float = builder.anim_time if builder else 0.0
	for i in 2:
		var phase := t * (0.6 + i * 0.25) + i * 2.0
		var wx := 6 + (sin(phase) * 0.5 + 0.5) * (fw - 14)
		var wy: float = top + 1 if i == 0 else maxf(top + 1, -6)
		if i == 1 and vis > 20:
			wy = -6 - 9 * floor((vis - 6) / 18.0)
		_draw_worker(Vector2(roundf(wx), wy), int(t * 6.0 + i) % 2 == 0, i)
	# Fortschritt
	var bw := fw - 8
	draw_rect(Rect2(4, top - 6, bw, 3), Pal.BLACK)
	draw_rect(Rect2(5, top - 5, int((bw - 2) * p), 1), Pal.YELLOW)


func _draw_worker(feet: Vector2, hit: bool, i: int) -> void:
	var shirt := Pal.OCHRE if i == 0 else Pal.BLUE
	draw_rect(Rect2(feet + Vector2(0, -2), Vector2(1, 2)), Pal.BLUE_D)
	draw_rect(Rect2(feet + Vector2(2, -2), Vector2(1, 2)), Pal.BLUE_D)
	draw_rect(Rect2(feet + Vector2(0, -5), Vector2(3, 3)), shirt)
	draw_rect(Rect2(feet + Vector2(0, -7), Vector2(3, 2)), Pal.SAND)
	draw_rect(Rect2(feet + Vector2(0, -8), Vector2(3, 1)), Pal.YELLOW)
	if hit:
		draw_rect(Rect2(feet + Vector2(3, -6), Vector2(2, 1)), Pal.STONE_L)
	else:
		draw_rect(Rect2(feet + Vector2(3, -5), Vector2(1, 2)), Pal.STONE_L)
