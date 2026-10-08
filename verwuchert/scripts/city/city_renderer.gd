class_name CityRenderer
extends Node2D
## Zeichnet den Boden: Gras, Teiche, Straßen, Raster und die Vorschau beim Bauen.

const T := 32

var builder: Node
var ground_tex: ImageTexture
var margin := 4
var _sparkles: Array[Vector3] = []


func setup(city_builder: Node) -> void:
	builder = city_builder
	use_parent_material = true
	var c: Dictionary = GameState.city
	var pond := Terrain.ponds(int(c.seed), int(c.w), int(c.h), Config.integer("city/pond_count", 1))
	var img := NatureArt.ground_image(int(c.seed), int(c.w), int(c.h), margin, pond)
	_paint_entry_road(img, int(c.h))
	ground_tex = ImageTexture.create_from_image(img)
	# Funkelnde Punkte auf dem Wasser
	var rng := RandomNumberGenerator.new()
	rng.seed = int(c.seed) + 3
	for i in pond.size():
		if pond[i] == 0:
			continue
		var tx := i % int(c.w)
		var ty := i / int(c.w)
		for k in 7:
			var p := Vector2(tx * T + rng.randi_range(8, 24), ty * T + rng.randi_range(8, 24))
			_sparkles.append(Vector3(p.x, p.y, rng.randf() * TAU))


## Die Landstraße kommt von links aus dem Wald. Sie liegt im Rand und gehört nicht zur Stadt.
func _paint_entry_road(img: Image, h: int) -> void:
	var row: int = builder.entry_row
	for k in margin:
		var tex := SpriteFactory.road(RoadArt.E | RoadArt.W, k + 1)
		var src := tex.get_image()
		img.blit_rect(src, Rect2i(0, 0, T, T), Vector2i(k * T, (row + margin) * T))
	h = h


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_texture(ground_tex, Vector2(-margin * T, -margin * T))
	_draw_sparkles()
	_draw_roads()
	if builder.tool != "":
		_draw_grid()
	_draw_coverage()
	_draw_preview()


func _draw_sparkles() -> void:
	var t: float = builder.anim_time
	for s in _sparkles:
		var v := sin(t * 1.3 + s.z)
		if v > 0.86:
			var col := Pal.WHITE if v > 0.95 else Pal.SKY
			draw_rect(Rect2(s.x, s.y, 1, 1), col)
			if v > 0.95:
				draw_rect(Rect2(s.x - 1, s.y, 3, 1), Pal.a(Pal.SKY, 0.6))


func _draw_roads() -> void:
	for t in builder.roads:
		var b: Dictionary = builder.roads[t]
		var mask: int = builder.road_mask(t)
		var tex := SpriteFactory.road(mask, (t.x * 7 + t.y * 13) % 6)
		var a := 1.0
		if b.state != "done":
			a = 0.35 + 0.65 * float(b.progress)
		draw_texture(tex, Vector2(t.x * T, t.y * T), Color(1, 1, 1, a))


func _draw_grid() -> void:
	var c: Dictionary = GameState.city
	var col := Pal.a(Pal.BLACK, 0.22)
	for y in int(c.h) + 1:
		for x in int(c.w) + 1:
			draw_rect(Rect2(x * T - 1, y * T, 3, 1), col)
			draw_rect(Rect2(x * T, y * T - 1, 1, 3), col)
	# Rand des Baugebiets
	var r := Rect2(0, 0, int(c.w) * T, int(c.h) * T)
	draw_rect(r, Pal.a(Pal.BONE, 0.25), false, 1.0)


## Versorgungsbereich von Wasserturm und Kraftwerk. Kleine Symbole statt einer Fläche,
## damit die Stadt sichtbar bleibt.
func _draw_coverage() -> void:
	var show_water: bool = builder.tool in ["water_tower", "house"] or builder.hover_type() == "water_tower"
	var show_power: bool = builder.tool in ["power_plant", "house", "shop", "factory"] or builder.hover_type() == "power_plant"
	if not show_water and not show_power:
		return
	var c: Dictionary = GameState.city
	for y in int(c.h):
		for x in int(c.w):
			var t := Vector2i(x, y)
			var base := Vector2(x * T, y * T)
			if show_power and builder.has_power(t):
				draw_rect(Rect2(base + Vector2(1, 1), Vector2(3, 1)), Pal.a(Pal.YELLOW, 0.55))
				draw_rect(Rect2(base + Vector2(1, 1), Vector2(1, 3)), Pal.a(Pal.YELLOW, 0.55))
			if show_water and builder.has_water(t):
				draw_rect(Rect2(base + Vector2(T - 4, T - 2), Vector2(3, 1)), Pal.a(Pal.SKY, 0.65))
				draw_rect(Rect2(base + Vector2(T - 2, T - 4), Vector2(1, 3)), Pal.a(Pal.SKY, 0.65))
	# Reichweite des Gebäudes in der Hand
	if builder.tool in ["water_tower", "power_plant"] and builder.hover_valid_tile():
		var size := BuildingTypes.size_of(builder.tool)
		var rad: float = Config.building(builder.tool).get("radius", 6)
		var center := Vector2(builder.hover.x + size.x * 0.5, builder.hover.y + size.y * 0.5)
		var col := Pal.SKY if builder.tool == "water_tower" else Pal.YELLOW
		for y in int(c.h):
			for x in int(c.w):
				if Vector2(x + 0.5, y + 0.5).distance_to(center) <= rad:
					draw_rect(Rect2(x * T + 2, y * T + 2, T - 4, T - 4), Pal.a(col, 0.1))
		var steps := 96
		for i in steps:
			if i % 2 == 0:
				continue
			var a := TAU * i / steps
			var p := center * T + Vector2(cos(a), sin(a)) * rad * T
			draw_rect(Rect2(p.round(), Vector2(2, 2)), Pal.a(col, 0.8))


func _draw_preview() -> void:
	var tool: String = builder.tool
	if tool == "" or not builder.hover_inside():
		return
	var ok_col := Pal.GRASS_L
	var bad_col := Pal.BRICK_L
	if tool == "road":
		for t in builder.road_preview():
			var valid: bool = builder.can_place("road", t)
			var col := ok_col if valid else bad_col
			draw_rect(Rect2(t.x * T, t.y * T, T, T), Pal.a(col, 0.28))
			draw_rect(Rect2(t.x * T, t.y * T, T, T), Pal.a(col, 0.8), false, 1.0)
		return
	if tool == "demolish":
		var b: Dictionary = builder.building_at(builder.hover)
		var r := Rect2(builder.hover.x * T, builder.hover.y * T, T, T)
		if not b.is_empty():
			r = Rect2(int(b.x) * T, int(b.y) * T, int(b.w) * T, int(b.h) * T)
		draw_rect(r, Pal.a(bad_col, 0.3))
		_brackets(r, bad_col)
		return
	var size := BuildingTypes.size_of(tool)
	var valid2: bool = builder.can_place(tool, builder.hover)
	var r2 := Rect2(builder.hover.x * T, builder.hover.y * T, size.x * T, size.y * T)
	var col2 := ok_col if valid2 else bad_col
	draw_rect(r2, Pal.a(col2, 0.22))
	_brackets(r2, col2)
	# Bäume, die weichen müssen
	for tv in builder.trees_in(Rect2i(builder.hover, size)):
		var p: Vector2 = tv.position
		draw_line(p + Vector2(-3, -3), p + Vector2(3, 3), Pal.BRICK_L)
		draw_line(p + Vector2(3, -3), p + Vector2(-3, 3), Pal.BRICK_L)


## Eckwinkel um eine Fläche.
func _brackets(r: Rect2, col: Color) -> void:
	var l := 6.0
	for corner in [r.position, Vector2(r.end.x - 1, r.position.y), Vector2(r.position.x, r.end.y - 1), r.end - Vector2.ONE]:
		var sx := 1.0 if corner.x <= r.position.x + 1 else -1.0
		var sy := 1.0 if corner.y <= r.position.y + 1 else -1.0
		var x0 := minf(corner.x, corner.x + sx * (l - 1))
		var y0 := minf(corner.y, corner.y + sy * (l - 1))
		draw_rect(Rect2(x0, corner.y, l, 1), col)
		draw_rect(Rect2(corner.x, y0, 1, l), col)
