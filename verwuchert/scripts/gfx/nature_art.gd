class_name NatureArt
extends RefCounted
## Bäume, Büsche, Steine und der Boden. Licht von oben links.

const LIGHT_DIR := Vector2(-0.6, -0.8)


## Laubkrone aus mehreren Ballen. Jeder Ballen bekommt eigenes Licht.
static func crown(c: PixelCanvas, rng: RandomNumberGenerator, center: Vector2, rx: float, ry: float, palette: Array = []) -> void:
	var cols: Array = palette if not palette.is_empty() else [Pal.MOSS_D, Pal.MOSS, Pal.GRASS, Pal.GRASS_L, Pal.LEAF_L]
	var blobs: Array = []
	blobs.append([center, maxf(rx, ry) * 0.62])
	var n := 7 + int(rx / 3.0)
	for i in n:
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(0.35, 0.72)
		var p := center + Vector2(cos(ang) * rx * dist, sin(ang) * ry * dist)
		blobs.append([p, rng.randf_range(0.32, 0.46) * (rx + ry) * 0.5])
	# Sortiert von hinten unten nach vorne oben, damit obere Ballen vorne liegen
	blobs.sort_custom(func(a, b): return a[0].y > b[0].y)
	var x0 := int(center.x - rx - 3)
	var x1 := int(center.x + rx + 3)
	var y0 := int(center.y - ry - 3)
	var y1 := int(center.y + ry + 3)
	for blob in blobs:
		var p: Vector2 = blob[0]
		var r: float = blob[1]
		for y in range(int(p.y - r) - 1, int(p.y + r) + 2):
			for x in range(int(p.x - r) - 1, int(p.x + r) + 2):
				var d := Vector2(x + 0.5, y + 0.5) - p
				var bump := sin(atan2(d.y, d.x) * 5.0 + p.x) * 0.9
				if d.length() > r + bump:
					continue
				var nrm := d / maxf(r, 0.01)
				var lit := -(nrm.dot(LIGHT_DIR.normalized())) * -1.0
				# Gesamtlicht: Ballen-Licht plus Lage in der Krone
				var global_d := (Vector2(x, y) - center) / Vector2(rx, ry)
				var gl := global_d.dot(LIGHT_DIR.normalized())
				var v := lit * 0.55 + gl * 0.65
				var idx := 2
				if v > 0.55:
					idx = 4 if PixelCanvas.bayer(x, y, 0.5) else 3
				elif v > 0.25:
					idx = 3
				elif v > -0.2:
					idx = 2 if not PixelCanvas.bayer(x, y, 0.25) else 3
				elif v > -0.5:
					idx = 1 if PixelCanvas.bayer(x, y, 0.6) else 2
				else:
					idx = 1 if PixelCanvas.bayer(x, y, 0.3) else 0
				c.px(x, y, cols[idx])
	# Blattglanz und Lücken
	for i in int(rx * ry * 0.18):
		var x := rng.randi_range(x0, x1)
		var y := rng.randi_range(y0, y1)
		if not c.is_solid(x, y):
			continue
		var gd := (Vector2(x, y) - center) / Vector2(rx, ry)
		if gd.dot(LIGHT_DIR.normalized()) > 0.2:
			c.px(x, y, cols[4])
		elif gd.dot(LIGHT_DIR.normalized()) < -0.3:
			c.px(x, y, cols[0])


static func oak(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var c := PixelCanvas.new(36, 52)
	var r := rng.randf_range(10.0, 13.0)
	var trunk_h := rng.randi_range(9, 12)
	var base := 50
	# Stamm mit Wurzelansatz
	c.rect(16, base - trunk_h - 6, 4, trunk_h + 6, Pal.WOOD)
	c.vline(16, base - trunk_h - 6, trunk_h + 6, Pal.WOOD_L)
	c.vline(19, base - trunk_h - 6, trunk_h + 6, Pal.SOIL)
	c.px(15, base, Pal.WOOD)
	c.px(20, base, Pal.SOIL)
	c.hline(14, base + 1, 8, Pal.SOIL_D)
	for y in range(base - trunk_h, base, 3):
		c.px(17 + (y % 2), y, Pal.SOIL)
	# Ast
	c.line(19, base - trunk_h - 2, 23, base - trunk_h - 6, Pal.WOOD)
	var center := Vector2(18, base - trunk_h - r * 0.7)
	crown(c, rng, center, r, r * 0.86)
	# Äste blitzen durch
	c.px(int(center.x) + 2, int(center.y) + 5, Pal.WOOD)
	c.px(int(center.x) - 3, int(center.y) + 3, Pal.SOIL)
	c.outline(Pal.MOSS_D, Pal.a(Pal.BLACK, 1.0))
	return {"tex": c.texture(), "size": Vector2i(c.w, c.h), "foot": Vector2(18, base),
		"split": int(center.y + r * 0.5), "radius": r, "height": base - int(center.y - r)}


static func pine(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var c := PixelCanvas.new(28, 56)
	var base := 54
	var height := rng.randi_range(38, 46)
	c.rect(13, base - 6, 3, 7, Pal.WOOD)
	c.vline(15, base - 6, 7, Pal.SOIL)
	c.hline(11, base + 1, 7, Pal.SOIL_D)
	var tiers := 4
	var top := base - height
	for t in tiers:
		var ty := top + int(float(t) / tiers * (height - 8))
		var by := ty + int((height - 4) / float(tiers)) + 6
		var half := 4.0 + t * 2.6
		for y in range(ty, by):
			var f := float(y - ty) / float(by - ty)
			var hw := half * f + 0.5
			for x in range(int(14 - hw), int(14 + hw) + 1):
				var s := (x - (14 - hw)) / maxf(1.0, hw * 2.0)
				var col := Pal.MOSS
				if s < 0.3:
					col = Pal.GRASS if PixelCanvas.bayer(x, y, 0.6) else Pal.MOSS
				elif s > 0.7:
					col = Pal.MOSS_D if PixelCanvas.bayer(x, y, 0.7) else Pal.TEAL_D
				if y >= by - 2:
					col = Pal.MOSS_D if (x + y) % 2 == 0 else Pal.TEAL_D
				c.px(x, y, col)
		# Zweigspitzen
		for k in int(half):
			var sx := rng.randi_range(int(14 - half), int(14 + half))
			c.px(sx, by, Pal.MOSS_D)
	c.px(14, top - 1, Pal.GRASS_L)
	c.px(13, top + 2, Pal.GRASS_L)
	c.outline(Pal.BLACK, Pal.MOSS_D)
	return {"tex": c.texture(), "size": Vector2i(c.w, c.h), "foot": Vector2(14, base),
		"split": base - 10, "radius": 8.0, "height": height}


static func bush(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var c := PixelCanvas.new(20, 18)
	crown(c, rng, Vector2(10, 10), 7.5, 5.5)
	if rng.randf() < 0.5:
		var berry: Color = [Pal.ROSE, Pal.BRICK_L, Pal.WHITE, Pal.YELLOW][rng.randi() % 4]
		for i in 6:
			var x := rng.randi_range(5, 15)
			var y := rng.randi_range(6, 13)
			if c.is_solid(x, y):
				c.px(x, y, berry)
	c.outline(Pal.MOSS_D, Pal.BLACK)
	return {"tex": c.texture(), "size": Vector2i(c.w, c.h), "foot": Vector2(10, 16),
		"split": 18, "radius": 7.0, "height": 12}


## Junger Trieb: ein dünner Stamm mit wenigen Blättern.
static func sapling(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var c := PixelCanvas.new(12, 14)
	var lean := rng.randi_range(-1, 1)
	c.rect(6, 7, 1, 6, Pal.WOOD)
	c.px(6 + lean, 6, Pal.WOOD)
	c.px(6, 12, Pal.SOIL)
	var cols := [Pal.LEAF_L, Pal.GRASS_L, Pal.GRASS]
	for p in [Vector2i(4, 5), Vector2i(8, 5), Vector2i(5, 3), Vector2i(7, 3), Vector2i(6, 2), Vector2i(3, 8), Vector2i(9, 8)]:
		c.px(p.x + lean, p.y, cols[rng.randi() % 3])
		if rng.randf() < 0.6:
			c.px(p.x + lean + 1, p.y, cols[rng.randi() % 3])
	c.px(6 + lean, 4, Pal.GRASS_L)
	c.outline(Pal.MOSS_D, Pal.BLACK)
	return {"tex": c.texture(), "size": Vector2i(c.w, c.h), "foot": Vector2(6, 12),
		"split": 14, "radius": 3.0, "height": 9}


static func rock(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var c := PixelCanvas.new(18, 14)
	var rx := rng.randf_range(5.0, 7.5)
	var ry := rng.randf_range(3.5, 5.0)
	var cen := Vector2(9, 12 - ry)
	for y in 14:
		for x in 18:
			var d := (Vector2(x + 0.5, y + 0.5) - cen) / Vector2(rx, ry)
			var bump := sin(x * 1.7 + seed_value) * 0.08
			if d.length() > 1.0 + bump or y > 12:
				continue
			var v := d.dot(LIGHT_DIR.normalized())
			var col := Pal.STONE
			if v > 0.35:
				col = Pal.STONE_L
			elif v > 0.1:
				col = Pal.STONE_L if PixelCanvas.bayer(x, y, 0.5) else Pal.STONE
			elif v < -0.45:
				col = Pal.STONE_D
			elif v < -0.2:
				col = Pal.STONE_D if PixelCanvas.bayer(x, y, 0.5) else Pal.STONE
			c.px(x, y, col)
	# Riss und Moos
	c.line(int(cen.x), int(cen.y - 1), int(cen.x + 2), int(cen.y + 2), Pal.STONE_D)
	if rng.randf() < 0.6:
		for i in 6:
			var x := rng.randi_range(int(cen.x - rx + 1), int(cen.x + 1))
			var y := rng.randi_range(int(cen.y - ry), int(cen.y - 1))
			if c.is_solid(x, y):
				c.px(x, y, Pal.GRASS if i % 2 == 0 else Pal.MOSS)
	c.outline(Pal.NIGHT, Pal.SLATE)
	return {"tex": c.texture(), "size": Vector2i(c.w, c.h), "foot": Vector2(9, 12),
		"split": 14, "radius": 6.0, "height": 6}


## Boden der ganzen Karte als ein Bild, mit Rand. Gras, Senken, Blumen, Teiche.
static func ground_image(seed_value: int, w: int, h: int, margin: int, pond: PackedByteArray) -> Image:
	return GroundJob.run_all(seed_value, w, h, margin, pond)


static func _is_pond(pond: PackedByteArray, w: int, h: int, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= w or y >= h:
		return false
	return pond[y * w + x] != 0


## Wasser mit weichem Ufer. Ein weiches Feld aus allen Teichfeldern ergibt runde, natürliche Formen.
## Das Wasser bleibt innerhalb der Teichfelder, damit es nie unter Gebäude läuft.
static func _pond_tile(img: Image, pond: PackedByteArray, w: int, h: int, tx: int, ty: int, ox: int, oy: int, rng: RandomNumberGenerator) -> void:
	const T := 32
	var centers: Array[Vector2] = []
	for ny in range(ty - 2, ty + 3):
		for nx in range(tx - 2, tx + 3):
			if _is_pond(pond, w, h, nx, ny):
				centers.append(Vector2(nx * T + 16, ny * T + 16))
	for py in T:
		for px in T:
			var wx := tx * T + px
			var wy := ty * T + py
			var gx := ox + wx
			var gy := oy + wy
			var v := 0.0
			for cc in centers:
				var d := Vector2(wx + 0.5, wy + 0.5).distance_to(cc) / 18.0
				v += exp(-d * d)
			v += sin(wx * 0.31 + wy * 0.17) * 0.04 + sin(wy * 0.23) * 0.03
			# Rand des Teichfelds zum Land: weich auslaufen lassen
			var col := Color(0, 0, 0, 0)
			if v > 1.7:
				col = Pal.TEAL_D
			elif v > 1.3:
				col = Pal.TEAL_D if PixelCanvas.bayer(gx, gy, (v - 1.3) * 2.5) else Pal.TEAL
			elif v > 0.8:
				col = Pal.TEAL
			elif v > 0.66:
				col = Pal.WATER if PixelCanvas.bayer(gx, gy, 0.6) else Pal.TEAL
			elif v > 0.56:
				col = Pal.WATER
			elif v > 0.5:
				col = Pal.SAND if PixelCanvas.bayer(gx, gy, 0.6) else Pal.WOOD_L
			elif v > 0.44:
				col = Pal.SOIL if (gx + gy) % 3 != 0 else Pal.SOIL_D
			elif v > 0.38:
				col = Pal.MOSS if PixelCanvas.bayer(gx, gy, 0.5) else Color(0, 0, 0, 0)
			if col.a > 0.0:
				img.set_pixel(gx, gy, col)
	# Schilf am Ufer und Seerosen
	for i in 10:
		var px := rng.randi_range(2, T - 3)
		var py := rng.randi_range(2, T - 3)
		var gx := ox + tx * T + px
		var gy := oy + ty * T + py
		var here := img.get_pixel(gx, gy)
		if here == Pal.WATER or here == Pal.SAND:
			var hgt := rng.randi_range(3, 6)
			for k in hgt:
				img.set_pixel(gx, gy - k, Pal.GRASS if k < hgt - 1 else Pal.GRASS_L)
			if rng.randf() < 0.5:
				img.set_pixel(gx, gy - hgt, Pal.SOIL)
				img.set_pixel(gx, gy - hgt + 1, Pal.SOIL)
		elif here == Pal.TEAL_D and rng.randf() < 0.5:
			for k in 3:
				img.set_pixel(gx + k, gy, Pal.GRASS)
				img.set_pixel(gx + k, gy + 1, Pal.MOSS)
			img.set_pixel(gx + 1, gy - 1, Pal.GRASS_L)
			if rng.randf() < 0.5:
				img.set_pixel(gx + 1, gy, Pal.ROSE)
