class_name CityRenderer
extends Node2D
## Zeichnet den Boden: Gras, Teiche, Straßen, Raster und die Vorschau beim Bauen.
## Alles Flache entsteht im Bodenraum (Quadrate) und wird mit Iso.GROUND zur Raute gekippt.
## Unter der Karte liegt eine Erdkante wie bei einem Diorama.

const T := 32
const CLIFF := 44

var builder: Node
var ground_tex: ImageTexture
var margin := 4
var _sparkles: Array[Vector3] = []
var _cliff_bits: Array = []


func setup(city_builder: Node) -> void:
	builder = city_builder
	margin = city_builder.MARGIN
	use_parent_material = true
	var c: Dictionary = GameState.city
	var pond := Terrain.ponds(int(c.seed), int(c.w), int(c.h), Config.integer("city/pond_count", 1))
	var img := NatureArt.ground_image(int(c.seed), int(c.w), int(c.h), margin, pond)
	_paint_entry_road(img)
	ground_tex = ImageTexture.create_from_image(img)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(c.seed) + 3
	for i in pond.size():
		if pond[i] == 0:
			continue
		var tx := i % int(c.w)
		var ty := i / int(c.w)
		for k in 7:
			_sparkles.append(Vector3(tx * T + rng.randi_range(8, 24), ty * T + rng.randi_range(8, 24), rng.randf() * TAU))
	_make_cliff_bits(rng)


## Die Landstraße kommt von links oben aus dem Wald. Sie liegt im Rand und gehört nicht zur Stadt.
func _paint_entry_road(img: Image) -> void:
	var row: int = builder.entry_row
	for k in margin:
		var src := SpriteFactory.road(RoadArt.E | RoadArt.W, k + 1).get_image()
		img.blit_rect(src, Rect2i(0, 0, T, T), Vector2i(k * T, (row + margin) * T))


## Steine, Wurzeln und Erdschichten an der Kante. Fest aus dem Seed.
func _make_cliff_bits(rng: RandomNumberGenerator) -> void:
	for i in 220:
		_cliff_bits.append({"f": rng.randf(), "side": rng.randi() % 2, "d": rng.randf_range(8, CLIFF - 4),
			"w": rng.randi_range(2, 5), "h": rng.randi_range(1, 3), "kind": rng.randi() % 5})


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_draw_cliff()
	draw_set_transform_matrix(Iso.GROUND)
	draw_texture(ground_tex, Vector2(-margin * T, -margin * T))
	_draw_sparkles()
	_draw_roads()
	_draw_network()
	if builder.tool != "":
		_draw_grid()
	_draw_preview()
	draw_set_transform_matrix(Transform2D.IDENTITY)
	_draw_hydrants()
	_draw_tree_marks()


## Erdschichten unter den beiden vorderen Kanten der Karte.
func _draw_cliff() -> void:
	var w: int = GameState.city.w
	var h: int = GameState.city.h
	var m := margin
	var left := Iso.to_screen(-m, h + m)
	var bottom := Iso.to_screen(w + m, h + m)
	var right := Iso.to_screen(w + m, -m)
	var layers := [
		[0, 3, Pal.MOSS, Pal.MOSS_D],
		[3, 12, Pal.SOIL, Pal.SOIL_D],
		[12, 22, Pal.SOIL_D, Pal.NIGHT],
		[22, 34, Pal.STONE_D, Pal.SLATE],
		[34, CLIFF, Pal.SLATE, Pal.NIGHT],
	]
	for L in layers:
		_band(left, bottom, L[0], L[1], L[2])
		_band(bottom, right, L[0], L[1], L[3])
	# Steine, Wurzeln, Würmer in der Erde
	for b in _cliff_bits:
		var a: Vector2 = left if b.side == 0 else bottom
		var e: Vector2 = bottom if b.side == 0 else right
		var p: Vector2 = a.lerp(e, b.f).round() + Vector2(0, b.d)
		var shade: bool = b.side == 1
		match b.kind:
			0, 1:
				if b.d > 14:
					var col := Pal.STONE if not shade else Pal.STONE_D
					draw_rect(Rect2(p, Vector2(b.w, b.h)), col)
					draw_rect(Rect2(p, Vector2(b.w, 1)), Pal.STONE_L if not shade else Pal.STONE)
			2:
				if b.d < 20:
					draw_line(p, p + Vector2(b.w - 2, b.h + 3), Pal.WOOD if not shade else Pal.SOIL)
			3:
				if b.d > 24:
					draw_rect(Rect2(p, Vector2(1, 1)), Pal.TEAL_D)
			_:
				draw_rect(Rect2(p, Vector2(b.w, 1)), Pal.SOIL_D if b.d < 22 else Pal.NIGHT)
	# Unterkante
	draw_line(left + Vector2(0, CLIFF), bottom + Vector2(0, CLIFF), Pal.BLACK)
	draw_line(bottom + Vector2(0, CLIFF), right + Vector2(0, CLIFF), Pal.BLACK)


func _band(a: Vector2, b: Vector2, d0: float, d1: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var steps := int(a.distance_to(b) / 6.0)
	for i in steps + 1:
		var f := float(i) / steps
		var wob := 0.0 if d0 == 0 else roundf(sin(f * 90.0 + d0) * 1.2)
		pts.append(a.lerp(b, f).round() + Vector2(0, d0 + wob))
	for i in range(steps, -1, -1):
		var f2 := float(i) / steps
		var wob2 := 0.0 if d1 == CLIFF else roundf(sin(f2 * 90.0 + d1) * 1.2)
		pts.append(a.lerp(b, f2).round() + Vector2(0, d1 + wob2))
	draw_colored_polygon(pts, col)


func _draw_sparkles() -> void:
	var t: float = builder.anim_time
	for s in _sparkles:
		var v := sin(t * 1.3 + s.z)
		if v > 0.86:
			var col := Pal.WHITE if v > 0.95 else Pal.SKY
			draw_rect(Rect2(s.x, s.y, 1, 1), col)


func _draw_roads() -> void:
	for t in builder.roads:
		var b: Dictionary = builder.roads[t]
		var mask: int = builder.road_mask(t)
		var tex := SpriteFactory.road(mask, (t.x * 7 + t.y * 13) % 6)
		var a := 1.0
		if b.state != "done":
			a = 0.35 + 0.65 * float(b.progress)
		draw_texture(tex, Vector2(t.x * T, t.y * T), Color(1, 1, 1, a))


## Welche Straßen Strom und Wasser führen. Nur sichtbar, wenn ein Werkzeug es braucht.
func _draw_network() -> void:
	var tool: String = builder.tool
	var hov: String = builder.hover_type()
	var show_power: bool = tool in ["power_plant", "house", "shop", "factory", "road"] or hov == "power_plant"
	var show_water: bool = tool in ["water_tower", "house", "road"] or hov == "water_tower"
	if not show_power and not show_water:
		return
	var pulse := 0.6 + 0.4 * sin(float(builder.anim_time) * 4.0)
	for t in builder.powered_roads:
		if show_power:
			draw_rect(Rect2(t.x * T + 13, t.y * T + 13, 6, 6), Pal.a(Pal.YELLOW, 0.55 * pulse))
	for t in builder.watered_roads:
		if show_water:
			draw_rect(Rect2(t.x * T + 9, t.y * T + 21, 4, 4), Pal.a(Pal.SKY, 0.75 * pulse))


func _draw_grid() -> void:
	var c: Dictionary = GameState.city
	var col := Pal.a(Pal.BLACK, 0.25)
	for y in int(c.h) + 1:
		for x in int(c.w) + 1:
			draw_rect(Rect2(x * T - 1, y * T, 3, 1), col)
			draw_rect(Rect2(x * T, y * T - 1, 1, 3), col)
	draw_rect(Rect2(0, 0, int(c.w) * T, int(c.h) * T), Pal.a(Pal.BONE, 0.3), false, 1.0)


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
			draw_rect(Rect2(t.x * T, t.y * T, T, T), Pal.a(col, 0.3))
			draw_rect(Rect2(t.x * T + 1, t.y * T + 1, T - 2, T - 2), Pal.a(col, 0.9), false, 1.0)
		return
	if tool == "demolish":
		var b: Dictionary = builder.building_at(builder.hover)
		var r := Rect2(builder.hover.x * T, builder.hover.y * T, T, T)
		if not b.is_empty():
			r = Rect2(int(b.x) * T, int(b.y) * T, int(b.w) * T, int(b.h) * T)
		draw_rect(r, Pal.a(bad_col, 0.35))
		draw_rect(r.grow(-1), Pal.a(bad_col, 0.9), false, 1.0)
		return
	var size := BuildingTypes.size_of(tool)
	var valid2: bool = builder.can_place(tool, builder.hover)
	var r2 := Rect2(builder.hover.x * T, builder.hover.y * T, size.x * T, size.y * T)
	var col2 := ok_col if valid2 else bad_col
	draw_rect(r2, Pal.a(col2, 0.25))
	draw_rect(r2.grow(-1), Pal.a(col2, 0.9), false, 1.0)


## Kleine rote Hydranten an Straßen mit Wasser.
func _draw_hydrants() -> void:
	for t in builder.watered_roads:
		if t.x < 0 or (t.x * 3 + t.y) % 4 != 1:
			continue
		var m: int = builder.road_mask(t)
		if m & RoadArt.S:
			continue
		var p := Iso.to_screen(t.x + 0.75, t.y + 0.9).round()
		draw_rect(Rect2(p + Vector2(-1, -4), Vector2(3, 4)), Pal.BRICK)
		draw_rect(Rect2(p + Vector2(-1, -4), Vector2(1, 4)), Pal.BRICK_L)
		draw_rect(Rect2(p + Vector2(-1, -5), Vector2(3, 1)), Pal.STONE_L)
		draw_rect(Rect2(p + Vector2(-2, -3), Vector2(5, 1)), Pal.BRICK_D)


## Bäume, die für den Bau weichen müssen, bekommen ein rotes Kreuz.
func _draw_tree_marks() -> void:
	var tool: String = builder.tool
	if tool == "" or tool == "demolish" or not builder.hover_inside():
		return
	var size := BuildingTypes.size_of(tool) if tool != "road" else Vector2i.ONE
	var tiles: Array = builder.road_preview() if tool == "road" else [builder.hover]
	for t in tiles:
		for tv in builder.trees_in(Rect2i(t, size)):
			var p: Vector2 = tv.position + Vector2(0, -4)
			draw_line(p + Vector2(-3, -3), p + Vector2(3, 3), Pal.BRICK_L)
			draw_line(p + Vector2(3, -3), p + Vector2(-3, 3), Pal.BRICK_L)
