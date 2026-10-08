class_name IsoCliff
extends RefCounted
## Erdkante unter einer isometrischen Karte wie bei einem Diorama. Geteilt von Stadt und Menü.
## Optional hängt unter der Kante eine Gesteinsspitze, dann schwebt die Karte als Insel.

const BASE_DEPTH := 44.0


## Steine, Wurzeln und Würmer in der Erde. Fest aus dem Seed.
static func make_bits(rng: RandomNumberGenerator, depth: int = 44) -> Array:
	var out := []
	for i in 220:
		out.append({"f": rng.randf(), "side": rng.randi() % 2, "d": rng.randf_range(8.0, depth - 4.0),
			"w": rng.randi_range(2, 5), "h": rng.randi_range(1, 3), "kind": rng.randi() % 5})
	return out


## Malt die beiden vorderen Wände. w und h zählen Felder, m ist der Rand um die Karte.
static func draw(ci: CanvasItem, w: int, h: int, m: int, bits: Array, depth: int = 44) -> void:
	var left := Iso.to_screen(-m, h + m)
	var bottom := Iso.to_screen(w + m, h + m)
	var right := Iso.to_screen(w + m, -m)
	var k := float(depth) / BASE_DEPTH
	var layers := [
		[0.0, 3.0 * k, Pal.MOSS, Pal.MOSS_D],
		[3.0 * k, 12.0 * k, Pal.SOIL, Pal.SOIL_D],
		[12.0 * k, 22.0 * k, Pal.SOIL_D, Pal.NIGHT],
		[22.0 * k, 34.0 * k, Pal.STONE_D, Pal.SLATE],
		[34.0 * k, float(depth), Pal.SLATE, Pal.NIGHT],
	]
	for L in layers:
		_band(ci, left, bottom, L[0], L[1], L[2], depth)
		_band(ci, bottom, right, L[0], L[1], L[3], depth)
	for b in bits:
		var a: Vector2 = left if b.side == 0 else bottom
		var e: Vector2 = bottom if b.side == 0 else right
		var d: float = float(b.d) * k
		var p: Vector2 = a.lerp(e, b.f).round() + Vector2(0, d)
		var shade: bool = b.side == 1
		match b.kind:
			0, 1:
				if d > 14.0 * k:
					var col := Pal.STONE if not shade else Pal.STONE_D
					ci.draw_rect(Rect2(p, Vector2(b.w, b.h)), col)
					ci.draw_rect(Rect2(p, Vector2(b.w, 1)), Pal.STONE_L if not shade else Pal.STONE)
			2:
				if d < 20.0 * k:
					ci.draw_line(p, p + Vector2(b.w - 2, b.h + 3), Pal.WOOD if not shade else Pal.SOIL)
			3:
				if d > 24.0 * k:
					ci.draw_rect(Rect2(p, Vector2(1, 1)), Pal.TEAL_D)
			_:
				ci.draw_rect(Rect2(p, Vector2(b.w, 1)), Pal.SOIL_D if d < 22.0 * k else Pal.NIGHT)
	ci.draw_line(left + Vector2(0, depth), bottom + Vector2(0, depth), Pal.BLACK)
	ci.draw_line(bottom + Vector2(0, depth), right + Vector2(0, depth), Pal.BLACK)


static func _band(ci: CanvasItem, a: Vector2, b: Vector2, d0: float, d1: float, col: Color, depth: int) -> void:
	var pts := PackedVector2Array()
	var steps := int(a.distance_to(b) / 6.0)
	for i in steps + 1:
		var f := float(i) / steps
		var wob := 0.0 if d0 == 0.0 else roundf(sin(f * 90.0 + d0) * 1.2)
		pts.append(a.lerp(b, f).round() + Vector2(0, d0 + wob))
	for i in range(steps, -1, -1):
		var f2 := float(i) / steps
		var wob2 := 0.0 if d1 == float(depth) else roundf(sin(f2 * 90.0 + d1) * 1.2)
		pts.append(a.lerp(b, f2).round() + Vector2(0, d1 + wob2))
	ci.draw_colored_polygon(pts, col)


## Gesteinsspitze unter der Kante. Gibt {tex, pos} zurück, pos ist die linke obere Ecke
## relativ zum oberen Eckpunkt der Karte. Jede Seite läuft zu einer zackigen Spitze zusammen.
static func underside(w: int, h: int, depth: int, taper: int, seed_value: int) -> Dictionary:
	var left := Iso.to_screen(0, h)
	var bottom := Iso.to_screen(w, h)
	var right := Iso.to_screen(w, 0)
	var ox := -int(left.x) + 2
	var top_y := int(minf(left.y, right.y)) + depth
	var img_w := int(right.x - left.x) + 6
	var img_h := int(bottom.y) + depth + taper - top_y + 6
	var c := PixelCanvas.new(img_w, img_h)
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.35
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for x in range(int(left.x), int(right.x) + 1):
		var on_left := x <= bottom.x
		var f: float
		var edge_y: float
		if on_left:
			f = (x - left.x) / maxf(1.0, bottom.x - left.x)
			edge_y = left.y + (x - left.x) * 0.5
		else:
			f = (right.x - x) / maxf(1.0, right.x - bottom.x)
			edge_y = right.y + (right.x - x) * 0.5
		var jag := 0.72 + (noise.get_noise_2d(x, 7) + 1.0) * 0.28
		var length := float(taper) * pow(f, 1.15) * jag
		var y0 := int(edge_y) + depth
		for yy in range(0, int(length)):
			var t := float(yy) / maxf(1.0, length)
			var col := Pal.STONE_D
			if t > 0.7:
				col = Pal.NIGHT
			elif t > 0.35:
				col = Pal.SLATE
			if PixelCanvas.bayer(x, yy, 0.5) and t > 0.25 and t < 0.75:
				col = Pal.SLATE if col == Pal.STONE_D else (Pal.NIGHT if col == Pal.SLATE else Pal.SLATE)
			if not on_left:
				col = Shade.dark(col)
			var n := noise.get_noise_2d(x * 1.7, yy * 2.1)
			if n > 0.55 and t < 0.6:
				col = Shade.light(col)
			c.px(x + ox, y0 + yy - top_y, col)
	# Wurzeln und Wurzelwerk hängen aus der Kante
	for i in 16:
		var rx := rng.randi_range(int(left.x) + 8, int(right.x) - 8)
		var on_left2 := rx <= bottom.x
		var ey: float = (left.y + (rx - left.x) * 0.5) if on_left2 else (right.y + (right.x - rx) * 0.5)
		var rl := rng.randi_range(5, 16)
		for k in rl:
			var col2 := Pal.WOOD if k < rl - 3 else Pal.SOIL
			if not on_left2:
				col2 = Shade.dark(col2)
			c.px(rx + ox + (1 if k % 5 == 4 else 0), int(ey) + depth + k - top_y, col2)
	c.outline(Pal.BLACK)
	return {"tex": c.texture(), "pos": Vector2(-ox, top_y)}
