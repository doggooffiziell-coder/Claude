class_name BuildingView
extends Node2D
## Ein Gebäude in der Welt. Zeigt Baustelle, Gerüst mit Arbeitern, fertiges Haus und nachts Licht.
## Die Position liegt auf der unteren Ecke der Felder, damit die Y-Sortierung stimmt.

var data: Dictionary
var art: Dictionary
var builder: Node
var status := {}
var pop := 0.0
var glow: Node2D
var _smoke_t := 0.0
var _last_state := ""
var _final_draw := false
## Wird kleiner, wenn ein Gebäude einstürzt. Der Schatten folgt.
var height_factor := 1.0


func setup(b: Dictionary, city_builder: Node) -> void:
	data = b
	builder = city_builder
	art = SpriteFactory.building_for(b)
	position = Iso.bottom(int(b.x), int(b.y), int(b.w), int(b.h))
	use_parent_material = true
	glow = Node2D.new()
	glow.set_script(preload("res://scripts/city/glow_view.gd"))
	add_child(glow)
	glow.setup(self)
	_last_state = b.state


func refresh_art() -> void:
	art = SpriteFactory.building_for(data)
	queue_redraw()


## Oberkante des Bildes in Weltkoordinaten. Dort erscheinen Blasen und Zahlen.
func top_point() -> Vector2:
	var anchor: Vector2 = art.anchor
	return position + Vector2(0, -anchor.y + int(art.get("top", 0)))


## Liegt ein Weltpunkt auf einem gemalten Pixel des Gebäudes?
func hit(p: Vector2) -> bool:
	if data.state != "done":
		return false
	var local: Vector2 = p - position + art.anchor
	var size: Vector2i = art.size
	if local.x < 0 or local.y < 0 or local.x >= size.x or local.y >= size.y:
		return false
	var img: Image = art.img
	return img.get_pixel(int(local.x), int(local.y)).a > 0.0


## Raute der Grundfläche relativ zur Position.
func footprint_local(inset := 0.0) -> PackedVector2Array:
	var x := float(data.x)
	var y := float(data.y)
	var w := float(data.w)
	var h := float(data.h)
	var pts := Iso.diamond(x + inset, y + inset, w - inset * 2.0, h - inset * 2.0)
	for i in pts.size():
		pts[i] -= position
	return pts


func is_done() -> bool:
	return data.state == "done"


func _process(delta: float) -> void:
	if data.state != _last_state:
		if data.state == "done":
			pop = 1.0
			refresh_art()
		_last_state = data.state
	if pop > 0.0:
		pop = maxf(0.0, pop - delta * 4.0)
		if pop <= 0.0:
			_final_draw = true
	var spd: float = builder.speed if builder else 1.0
	if data.state == "done" and spd > 0.0:
		_smoke_t -= delta * spd
		if _smoke_t <= 0.0:
			_emit_smoke()
	elif data.state == "building" and spd > 0.0:
		if randf() < delta * 3.0 * spd:
			var fp := footprint_local(0.1)
			var a: Vector2 = fp[3].lerp(fp[1], randf())
			builder.particles.emit("dust", position + a.lerp(fp[2], randf() * 0.6), 2)
	# Ein fertiges Haus ändert sich nicht, es wird nur beim Einpoppen und auf der Baustelle neu gemalt
	if data.state != "done" or pop > 0.0 or _final_draw:
		_final_draw = false
		queue_redraw()


func _emit_smoke() -> void:
	var smoke: Array = art.get("smoke", [])
	if smoke.is_empty():
		_smoke_t = 99.0
		return
	var origin: Vector2 = position - art.anchor
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
			if status.get("active", false):
				builder.particles.emit("steam", origin + smoke[0], 1)
		_:
			_smoke_t = 1.0


func _draw() -> void:
	var size: Vector2i = art.size
	var anchor: Vector2 = art.anchor
	var origin := -anchor
	match data.state:
		"queued":
			_draw_site(false)
		"building":
			_draw_site(true)
			var p: float = clampf(float(data.progress), 0.0, 1.0)
			var ease := p * p * (3.0 - 2.0 * p)
			# Das Gebäude wächst von unten nach oben aus dem Boden
			var full := float(size.y)
			var vis := int(round(lerpf(anchor.y * 0.0 + 18.0, full, ease)))
			vis = clampi(vis, 1, size.y)
			var src := Rect2(0, size.y - vis, size.x, vis)
			draw_texture_rect_region(art.tex, Rect2(origin.x, origin.y + size.y - vis, size.x, vis), src)
			_draw_scaffold(vis - (size.y - int(anchor.y)), p)
		_:
			if pop > 0.0:
				var k := sin(pop * PI)
				var sx := 1.0 + k * 0.05
				var sy := 1.0 + k * 0.08
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(sx, sy))
			draw_texture(art.tex, origin)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Baugrund: abgesteckte Raute mit Pflöcken und rot-weißem Band.
func _draw_site(started: bool) -> void:
	var fp := footprint_local(0.06)
	draw_colored_polygon(fp, Pal.a(Pal.SOIL, 0.85 if started else 0.45))
	if started:
		var inner := footprint_local(0.16)
		draw_colored_polygon(inner, Pal.a(Pal.STONE_L, 0.9))
	for i in 4:
		var a: Vector2 = fp[i]
		var b: Vector2 = fp[(i + 1) % 4]
		var steps := int(a.distance_to(b))
		for k in steps:
			var q := a.lerp(b, float(k) / steps).round()
			var col := Pal.BRICK_L if (k / 3) % 2 == 0 else Pal.WHITE
			draw_rect(Rect2(q + Vector2(0, -2), Vector2.ONE), col)
		draw_rect(Rect2(a.round() + Vector2(0, -4), Vector2(1, 4)), Pal.WOOD_L)
		draw_rect(Rect2(a.round() + Vector2(0, -4), Vector2(1, 1)), Pal.BRICK_L)
	if not started:
		var t: float = builder.anim_time if builder else 0.0
		var bob := roundf(sin(t * 3.0) * 1.0)
		var c := (fp[0] + fp[2]) * 0.5
		draw_texture(IconArt.get_icon("hourglass"), c + Vector2(-4, -14 + bob))


## Gerüst an den drei sichtbaren Ecken, Bretter entlang der Wände, zwei Arbeiter.
func _draw_scaffold(height: int, p: float) -> void:
	var fp := footprint_local(0.08)
	var left: Vector2 = fp[3].round()
	var bottom: Vector2 = fp[2].round()
	var right: Vector2 = fp[1].round()
	var top_h := maxi(6, height + 3)
	for c in [left, bottom, right]:
		draw_rect(Rect2(c + Vector2(0, -top_h), Vector2(1, top_h)), Pal.WOOD)
		draw_rect(Rect2(c + Vector2(1, -top_h), Vector2(1, top_h)), Pal.SOIL)
	var lvl := 8
	while lvl < top_h:
		draw_line(left + Vector2(0, -lvl), bottom + Vector2(0, -lvl), Pal.WOOD_L)
		draw_line(bottom + Vector2(0, -lvl), right + Vector2(0, -lvl), Pal.WOOD)
		lvl += 9
	draw_line(left + Vector2(0, -top_h), bottom + Vector2(0, -top_h), Pal.WOOD_L)
	draw_line(bottom + Vector2(0, -top_h), right + Vector2(0, -top_h), Pal.WOOD)
	# Kran bei großen Gebäuden
	if int(data.w) > 1:
		var base := right + Vector2(-4, -top_h)
		draw_rect(Rect2(base + Vector2(0, -20), Vector2(1, 20)), Pal.OCHRE)
		draw_rect(Rect2(base + Vector2(-26, -20), Vector2(30, 1)), Pal.OCHRE)
		var t0: float = builder.anim_time if builder else 0.0
		var hook_y := roundf(sin(t0 * 1.5) * 3.0) + 8.0
		draw_rect(Rect2(base + Vector2(-20, -19), Vector2(1, hook_y)), Pal.STONE_L)
		draw_rect(Rect2(base + Vector2(-22, -19 + hook_y), Vector2(4, 2)), Pal.STONE_D)
	# Arbeiter laufen auf den Brettern
	var t: float = builder.anim_time if builder else 0.0
	for i in 2:
		var phase := t * (0.5 + i * 0.25) + i * 2.0
		var f := sin(phase) * 0.5 + 0.5
		var on_left := i == 0
		var a := (left if on_left else bottom)
		var b := (bottom if on_left else right)
		var y_off := -float(mini(top_h, 8 + 9 * (i % 2)))
		var feet := a.lerp(b, 0.15 + f * 0.7).round() + Vector2(0, y_off)
		_draw_worker(feet, int(t * 6.0 + i) % 2 == 0, i)
	# Fortschritt
	var bw := 26
	var bar_pos := Vector2(-bw / 2, -top_h - 8 + bottom.y)
	draw_rect(Rect2(bar_pos, Vector2(bw, 3)), Pal.BLACK)
	draw_rect(Rect2(bar_pos + Vector2(1, 1), Vector2(int((bw - 2) * p), 1)), Pal.YELLOW)


func _draw_worker(feet: Vector2, hit_now: bool, i: int) -> void:
	var shirt := Pal.OCHRE if i == 0 else Pal.BLUE
	draw_rect(Rect2(feet + Vector2(0, -2), Vector2(1, 2)), Pal.BLUE_D)
	draw_rect(Rect2(feet + Vector2(2, -2), Vector2(1, 2)), Pal.BLUE_D)
	draw_rect(Rect2(feet + Vector2(0, -5), Vector2(3, 3)), shirt)
	draw_rect(Rect2(feet + Vector2(0, -7), Vector2(3, 2)), Pal.SAND)
	draw_rect(Rect2(feet + Vector2(0, -8), Vector2(3, 1)), Pal.YELLOW)
	if hit_now:
		draw_rect(Rect2(feet + Vector2(3, -6), Vector2(2, 1)), Pal.STONE_L)
	else:
		draw_rect(Rect2(feet + Vector2(3, -5), Vector2(1, 2)), Pal.STONE_L)
