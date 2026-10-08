class_name BuildingArt
extends RefCounted
## Malt alle Gebäude in leichter Schrägansicht. Licht von oben links.
## Jedes Gebäude bekommt ein Farbbild und ein Leuchtbild für die Nacht.
## Das Bild sitzt mit der Unterkante auf der Unterkante seiner Felder.

const CLEAR := Color(0, 0, 0, 0)
const GLASS_GLOW := Pal.YELLOW
const GLOW_EDGE := Pal.OCHRE


static func _result(c: PixelCanvas, g: PixelCanvas, meta: Dictionary) -> Dictionary:
	# Oberste gemalte Zeile, für Blasen und Texte über dem Dach
	var top := 0
	var found := false
	for y in c.h:
		for x in c.w:
			if c.img.get_pixel(x, y).a > 0.0:
				found = true
				break
		if found:
			top = y
			break
	meta["top"] = top
	meta["tex"] = c.texture()
	meta["glow"] = g.texture()
	meta["size"] = Vector2i(c.w, c.h)
	return meta


static func _pick(rng: RandomNumberGenerator, options: Array):
	return options[rng.randi() % options.size()]


# Bausteine

## Wand mit Material-Struktur. Ziegel im Verband, Holz als Bretter, Beton als Platten.
static func _wall(c: PixelCanvas, rng: RandomNumberGenerator, x: int, y: int, ww: int, wh: int, base: Color, material: String) -> void:
	var lt := Shade.light(base)
	var dk := Shade.dark(base)
	c.rect(x, y, ww, wh, base)
	match material:
		"ziegel":
			for r in wh:
				var yy := y + r
				if r % 3 == 2:
					c.hline(x, yy, ww, dk)
					continue
				var course := r / 3
				for xx in range(x, x + ww):
					if (xx - x + (course % 2) * 3) % 6 == 5:
						c.px(xx, yy, dk)
			# Einzelne Ziegel heller oder dunkler
			for n in int(ww * wh / 22):
				var bx := x + rng.randi_range(0, ww - 4)
				var by := y + rng.randi_range(0, wh - 2)
				if (by - y) % 3 == 2:
					continue
				var col := lt if rng.randf() < 0.6 else dk
				for k in 3:
					if c.get_px(bx + k, by).is_equal_approx(base):
						c.px(bx + k, by, col)
		"holz":
			for r in wh:
				var yy := y + r
				if r % 3 == 0:
					c.hline(x, yy, ww, lt)
				elif r % 3 == 2:
					c.hline(x, yy, ww, dk)
			for n in int(ww * wh / 40):
				c.px(x + rng.randi_range(1, ww - 2), y + rng.randi_range(0, wh - 1), dk)
		"beton":
			for r in wh:
				if r % 8 == 7:
					c.hline(x, y + r, ww, dk)
			for xx in range(x + 7, x + ww - 1, 8):
				c.vline(xx, y, wh, dk)
			c.speckle(x, y, ww, wh, lt, 0.04, rng)
			c.speckle(x, y, ww, wh, dk, 0.03, rng)
		"stahl":
			for xx in range(x, x + ww):
				var k := (xx - x) % 4
				if k == 0:
					c.vline(xx, y, wh, lt)
				elif k == 3:
					c.vline(xx, y, wh, dk)
	# Licht von links, Schatten rechts
	c.vline(x, y, wh, lt)
	c.dither(x + ww - 2, y, 2, wh, dk, 0.5)
	c.vline(x + ww - 1, y, wh, dk)


## Fenster mit Rahmen, Sprosse, Spiegelung und Vorhang. Leuchtet nachts.
static func _window(c: PixelCanvas, g: PixelCanvas, rng: RandomNumberGenerator, x: int, y: int, ww: int, wh: int, frame: Color, curtain := true, cross := true) -> void:
	c.rect(x, y, ww, wh, frame)
	var gx := x + 1
	var gy := y + 1
	var gw := ww - 2
	var gh := wh - 2
	# Glas: oben heller Himmel, unten dunkel
	c.rect(gx, gy, gw, gh, Pal.BLUE_D)
	c.hline(gx, gy, gw, Pal.BLUE)
	c.px(gx, gy, Pal.SKY)
	if gh > 3:
		c.px(gx + 1, gy + 1, Pal.BLUE)
	g.rect(gx, gy, gw, gh, GLASS_GLOW)
	g.hline(gx, gy + gh - 1, gw, GLOW_EDGE)
	if curtain:
		var cc: Color = _pick(rng, [Pal.ROSE, Pal.OCHRE, Pal.BONE, Pal.TEAL, Pal.SAND])
		c.vline(gx + gw - 1, gy, mini(3, gh), cc)
		c.px(gx + gw - 2, gy, cc)
		g.vline(gx + gw - 1, gy, mini(3, gh), GLOW_EDGE)
	# Sprossen: waagerecht immer, senkrecht nur bei breiten Fenstern
	if cross and gh >= 4:
		var my := gy + gh / 2 - 1
		c.hline(gx, my, gw, frame)
		g.clear(gx, my, gw, 1)
	if cross and gw >= 5:
		var mx := gx + gw / 2
		c.vline(mx, gy, gh, frame)
		g.clear(mx, gy, 1, gh)
	# Fensterbank
	c.hline(x - 1, y + wh, ww + 2, Pal.STONE_L)
	c.px(x + ww, y + wh, Pal.STONE)
	# Lichtschein auf der Wand
	for yy in range(y - 1, y + wh + 1):
		g.px(x - 1, yy, Pal.a(GLOW_EDGE, 0.22))
		g.px(x + ww, yy, Pal.a(GLOW_EDGE, 0.22))
	g.hline(x, y + wh + 1, ww, Pal.a(GLOW_EDGE, 0.3))


static func _flower_box(c: PixelCanvas, rng: RandomNumberGenerator, x: int, y: int, ww: int) -> void:
	c.rect(x, y + 1, ww, 2, Pal.WOOD)
	c.hline(x, y + 1, ww, Pal.WOOD_L)
	for xx in range(x, x + ww):
		c.px(xx, y, Pal.GRASS if (xx % 2 == 0) else Pal.MOSS)
		if rng.randf() < 0.45:
			c.px(xx, y, _pick(rng, [Pal.ROSE, Pal.YELLOW, Pal.WHITE, Pal.BRICK_L]))


static func _door(c: PixelCanvas, g: PixelCanvas, x: int, bottom: int, dw: int, dh: int, col: Color, frame: Color) -> void:
	var top := bottom - dh + 1
	c.rect(x - 1, top - 1, dw + 2, dh + 1, frame)
	c.rect(x, top, dw, dh, col)
	c.vline(x, top, dh, Shade.light(col))
	c.vline(x + dw - 1, top, dh, Shade.dark(col))
	# Füllungen
	c.frame(x + 1, top + 1, dw - 2, dh / 2 - 1, Shade.dark(col))
	c.frame(x + 1, top + dh / 2 + 1, dw - 2, dh / 2 - 2, Shade.dark(col))
	c.px(x + dw - 2, top + dh / 2, Pal.YELLOW)
	# Lampe neben der Tür
	c.px(x + dw + 1, top + 1, Pal.STONE_D)
	c.px(x + dw + 2, top + 1, Pal.YELLOW)
	c.px(x + dw + 2, top + 2, Pal.OCHRE)
	g.px(x + dw + 2, top + 1, Pal.WHITE)
	g.px(x + dw + 2, top + 2, Pal.YELLOW)
	for p in [Vector2i(1, 0), Vector2i(3, 1), Vector2i(1, 3), Vector2i(3, 2), Vector2i(2, 3), Vector2i(2, 0)]:
		g.px(x + dw + p.x, top + p.y, Pal.a(Pal.OCHRE, 0.45))
	# Stufe
	c.rect(x - 1, bottom + 1, dw + 2, 1, Pal.STONE_L)
	c.hline(x - 1, bottom + 2, dw + 2, Pal.STONE)


## Schindeldach, Firstlinie oben. Reihen werden nach oben heller.
static func _shingles(c: PixelCanvas, rng: RandomNumberGenerator, x: int, y: int, rw: int, rh: int, base: Color) -> void:
	var lt := Shade.light(base)
	var dk := Shade.dark(base)
	c.rect(x, y, rw, rh, base)
	for r in rh:
		var yy := y + rh - 1 - r
		if r % 3 == 0:
			c.hline(x, yy, rw, dk)
			continue
		var course := r / 3
		for xx in range(x, x + rw):
			if (xx + course * 2) % 4 == 0 and r % 3 == 1:
				c.px(xx, yy, dk)
	c.dither(x, y, rw, rh / 3, lt, 0.5)
	c.hline(x, y, rw, lt)
	for n in rw * rh / 18:
		var sx := x + rng.randi_range(0, rw - 2)
		var sy := y + rng.randi_range(1, rh - 2)
		if c.get_px(sx, sy).is_equal_approx(base):
			c.px(sx, sy, lt if rng.randf() < 0.5 else dk)
	c.dither(x + rw - 3, y, 3, rh, dk, 0.5)


static func _chimney(c: PixelCanvas, x: int, top: int, height: int, meta: Dictionary) -> void:
	c.rect(x, top, 4, height, Pal.BRICK)
	c.vline(x, top, height, Pal.BRICK_L)
	c.vline(x + 3, top, height, Pal.BRICK_D)
	for yy in range(top + 2, top + height, 3):
		c.hline(x, yy, 4, Pal.BRICK_D)
	c.rect(x - 1, top - 1, 6, 2, Pal.STONE_D)
	c.hline(x - 1, top - 1, 6, Pal.STONE)
	c.px(x + 1, top - 1, Pal.BLACK)
	c.px(x + 2, top - 1, Pal.BLACK)
	meta.smoke.append(Vector2(x + 2, top - 2))


# Wohnhaus

static func house(variant: int, material: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = variant
	var c := PixelCanvas.new(32, 64)
	var g := PixelCanvas.new(32, 64)
	var meta := {"smoke": [], "blink": []}
	var style: String = _pick(rng, ["ridge", "gable", "tall", "ridge", "gable"])
	if material == "holz" and style == "tall":
		style = "gable"
	var roof: Color = _pick(rng, [Pal.BRICK_D, Pal.SLATE, Pal.TEAL_D, Pal.PLUM, Pal.SOIL, Pal.STONE_D, Pal.BRICK])
	var wall: Color = Pal.BRICK
	if material == "holz":
		wall = _pick(rng, [Pal.WOOD, Pal.TEAL, Pal.SAND, Pal.STONE_L, Pal.BLUE, Pal.WOOD_L])
	var trim: Color = Pal.BONE if wall != Pal.STONE_L else Pal.WHITE
	var door_col: Color = _pick(rng, [Pal.TEAL_D, Pal.BRICK_D, Pal.BLUE_D, Pal.WOOD, Pal.MOSS, Pal.PLUM])
	var wl := 4
	var ww := 24
	var bottom := 57
	var wh := 26 if style == "tall" else 16
	var top := bottom - wh + 1
	var door_x: int = 13 if rng.randf() < 0.6 else _pick(rng, [6, 20])

	# Wand
	_wall(c, rng, wl, top, ww, wh, wall, material)
	if material == "holz":
		c.vline(wl, top, wh, trim)
		c.vline(wl + ww - 1, top, wh, Shade.dark(trim))
	# Sockel
	c.rect(wl, bottom - 1, ww, 2, Pal.STONE_D)
	c.hline(wl, bottom - 1, ww, Pal.STONE)

	# Fenster und Tür
	var win_xs: Array = []
	match door_x:
		13: win_xs = [6, 20]
		6: win_xs = [14, 21]
		_: win_xs = [6, 13]
	var shutters := material == "holz" and rng.randf() < 0.55
	var shutter_col: Color = _pick(rng, [Pal.MOSS, Pal.TEAL_D, Pal.BRICK_D, Pal.BLUE_D])
	var rows: Array = [top + 4] if style != "tall" else [top + 3, top + 14]
	for ry in rows:
		for wx in win_xs:
			_window(c, g, rng, wx, ry, 6, 7, trim)
			if shutters:
				c.vline(wx - 2, ry, 7, shutter_col)
				c.vline(wx + 6, ry, 7, shutter_col)
				for k in range(ry + 1, ry + 7, 2):
					c.px(wx - 2, k, Shade.dark(shutter_col))
					c.px(wx + 6, k, Shade.dark(shutter_col))
			if ry == rows[rows.size() - 1] and rng.randf() < 0.6:
				_flower_box(c, rng, wx - 1, ry + 8, 8)
		if style == "tall" and ry == rows[0]:
			# Obergeschoss: auch über der Tür ein Fenster
			_window(c, g, rng, door_x, ry, 6, 7, trim)
	if style == "tall":
		# Gesims zwischen den Stockwerken
		c.hline(wl, top + 12, ww, Shade.light(wall))
		c.hline(wl, top + 13, ww, Shade.dark(wall))
	_door(c, g, door_x, bottom - 2, 6, 10, door_col, trim)
	# Hausnummer
	c.px(door_x + 2, bottom - 13 if style != "tall" else bottom - 13, Pal.WHITE)

	# Dach
	match style:
		"ridge":
			var rt := top - 14
			_shingles(c, rng, 2, rt, 28, 14, roof)
			c.hline(1, top - 1, 30, Shade.dark(Shade.dark(roof)))
			c.hline(2, rt - 1, 28, Shade.light(Shade.light(roof)))
			c.dither(wl, top, ww, 2, Pal.a(Pal.BLACK, 1.0), 0.25)
			if rng.randf() < 0.45:
				# Gaube
				var gx := 12
				c.rect(gx, rt + 4, 8, 7, wall)
				_window(c, g, rng, gx + 1, rt + 6, 6, 5, trim, false)
				c.rect(gx - 1, rt + 2, 10, 3, Shade.dark(roof))
				c.hline(gx - 1, rt + 2, 10, Shade.light(roof))
			_chimney(c, _pick(rng, [5, 22]), rt - 5, 9, meta)
		"gable":
			var apex := Vector2(16, top - 13)
			var d := 11.0
			var left := PackedVector2Array([Vector2(2, top + 1), apex, apex + Vector2(0, -d), Vector2(2, top + 1 - d)])
			var right := PackedVector2Array([apex, Vector2(30, top + 1), Vector2(30, top + 1 - d), apex + Vector2(0, -d)])
			c.poly(left, Shade.light(roof))
			c.poly(right, roof)
			# Schindelreihen parallel zur Traufe
			for y in range(0, 64):
				for x in range(0, 32):
					var col := c.get_px(x, y)
					if col.is_equal_approx(Shade.light(roof)) and (x + y) % 3 == 0:
						c.px(x, y, roof)
					elif col.is_equal_approx(roof) and (y - x + 64) % 3 == 0:
						c.px(x, y, Shade.dark(roof))
			c.line(int(apex.x), int(apex.y - d), int(apex.x), int(apex.y), Shade.light(Shade.light(roof)))
			# Giebelwand vor dem Dach
			var gable := PackedVector2Array([Vector2(wl, top), Vector2(16, top - 11), Vector2(wl + ww, top)])
			var gc := PixelCanvas.new(32, 64)
			_wall(gc, rng, wl, top - 12, ww, 12, wall, material)
			for y in range(top - 12, top):
				for x in range(wl, wl + ww):
					if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), gable):
						c.px(x, y, gc.get_px(x, y))
			# Rundfenster im Giebel
			c.disc(16, top - 5, 2.5, trim)
			c.disc(16, top - 5, 1.6, Pal.BLUE_D)
			c.px(15, top - 6, Pal.SKY)
			g.disc(16, top - 5, 1.6, GLASS_GLOW)
			# Windbretter
			c.line(2, top, 16, top - 14, trim)
			c.line(16, top - 14, 30, top, Shade.dark(trim))
			c.dither(wl, top, ww, 2, Pal.BLACK, 0.25)
			_chimney(c, 22, top - 22, 8, meta)
		"tall":
			var rt := top - 10
			c.rect(wl, rt, ww, 10, Pal.STONE_D)
			c.speckle(wl, rt, ww, 10, Pal.SLATE, 0.18, rng)
			c.speckle(wl, rt, ww, 10, Pal.STONE, 0.06, rng)
			# Brüstung
			c.rect(wl - 1, rt - 1, ww + 2, 2, Shade.light(wall))
			c.vline(wl - 1, rt, 11, Shade.light(wall))
			c.vline(wl + ww, rt, 11, Shade.dark(wall))
			c.rect(wl - 1, top - 2, ww + 2, 2, Shade.light(wall))
			c.hline(wl - 1, top - 1, ww + 2, Shade.dark(wall))
			# Oberlicht und Antenne
			c.rect(wl + 3, rt + 3, 6, 4, Pal.BLUE)
			c.frame(wl + 3, rt + 3, 6, 4, Pal.STONE_L)
			c.px(wl + 4, rt + 4, Pal.SKY)
			c.vline(wl + 18, rt - 7, 9, Pal.STONE_L)
			c.hline(wl + 15, rt - 6, 7, Pal.STONE_L)
			c.hline(wl + 16, rt - 4, 5, Pal.STONE_L)
			meta.blink.append(Vector2(wl + 18, rt - 8))
			_chimney(c, wl + 12, rt - 3, 6, meta)

	c.outline(Pal.NIGHT, Pal.a(Pal.NIGHT, 1.0))

	# Vorgarten ohne Kontur
	var path_col := Pal.STONE_L
	for y in range(bottom + 3, 64):
		c.hline(door_x, y, 6, path_col)
		if (y - bottom) % 2 == 0:
			c.px(door_x + ((y / 2) % 3) * 2, y, Pal.STONE)
	var fence: Color = _pick(rng, [Pal.BONE, Pal.WOOD_L, Pal.WOOD])
	if rng.randf() < 0.7:
		for x in range(1, 31):
			if x >= door_x - 1 and x <= door_x + 6:
				continue
			if x % 2 == 1:
				c.vline(x, 59, 4, fence)
				c.px(x, 59, Shade.light(fence))
			c.px(x, 60, Shade.dark(fence))
	if rng.randf() < 0.7:
		var bx: int = 26 if door_x < 16 else 2
		c.disc(bx + 2, bottom - 1, 2.6, Pal.MOSS)
		c.disc(bx + 1.5, bottom - 1.5, 1.6, Pal.GRASS)
		c.px(bx + 1, bottom - 3, Pal.GRASS_L)
		if rng.randf() < 0.5:
			c.px(bx + 3, bottom - 2, Pal.ROSE)
			c.px(bx + 1, bottom, Pal.ROSE)
	# Briefkasten
	var mx: int = door_x + 8 if door_x < 20 else door_x - 3
	c.vline(mx, 59, 4, Pal.STONE_D)
	c.rect(mx - 1, 57, 3, 2, _pick(rng, [Pal.BLUE, Pal.BRICK, Pal.OCHRE]))
	return _result(c, g, meta)


# Laden

static func shop(variant: int, material: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = variant
	var c := PixelCanvas.new(32, 64)
	var g := PixelCanvas.new(32, 64)
	var meta := {"smoke": [], "blink": []}
	var wall: Color = Pal.BRICK if material == "ziegel" else Pal.STONE_L
	var awning: Color = _pick(rng, [Pal.ROSE, Pal.TEAL, Pal.OCHRE, Pal.BRICK, Pal.MOSS, Pal.BLUE])
	var kind: String = _pick(rng, ["can", "bread", "bottle"])
	var wl := 3
	var ww := 26
	var bottom := 57
	var top := 35
	var wh := bottom - top + 1

	_wall(c, rng, wl, top, ww, wh, wall, material)
	# Flachdach mit Brüstung
	var rt := top - 11
	c.rect(wl, rt, ww, 11, Pal.SLATE)
	c.speckle(wl, rt, ww, 11, Pal.STONE_D, 0.25, rng)
	c.rect(wl - 1, rt - 1, ww + 2, 2, Shade.light(wall))
	c.vline(wl - 1, rt, 12, Shade.light(wall))
	c.vline(wl + ww, rt, 12, Shade.dark(wall))
	c.rect(wl - 1, top - 2, ww + 2, 2, Shade.light(wall))
	c.hline(wl - 1, top - 1, ww + 2, Shade.dark(wall))
	# Klimagerät
	c.rect(wl + 15, rt + 2, 8, 6, Pal.STONE_L)
	c.hline(wl + 15, rt + 2, 8, Pal.WHITE)
	c.vline(wl + 22, rt + 2, 6, Pal.STONE)
	c.disc(wl + 18.5, rt + 5.5, 2, Pal.STONE)
	c.px(wl + 18, rt + 5, Pal.STONE_D)
	c.rect(wl + 3, rt + 4, 3, 3, Pal.STONE)
	c.px(wl + 3, rt + 4, Pal.STONE_L)

	# Schild mit Symbol
	var sy := top + 1
	c.rect(wl + 2, sy, ww - 4, 6, Pal.NIGHT)
	c.frame(wl + 2, sy, ww - 4, 6, Pal.WOOD)
	c.hline(wl + 2, sy, ww - 4, Pal.WOOD_L)
	var ix := wl + ww / 2 - 2
	match kind:
		"can":
			for k in 3:
				var cx := wl + 6 + k * 6
				c.rect(cx, sy + 1, 3, 4, Pal.BRICK_L)
				c.hline(cx, sy + 1, 3, Pal.STONE_L)
				c.hline(cx, sy + 4, 3, Pal.STONE_L)
				c.px(cx + 1, sy + 2, Pal.BONE)
				g.rect(cx, sy + 1, 3, 4, Pal.ROSE)
		"bread":
			for k in 3:
				var bx := wl + 5 + k * 6
				c.rect(bx, sy + 2, 5, 3, Pal.OCHRE)
				c.hline(bx + 1, sy + 1, 3, Pal.OCHRE)
				c.px(bx + 1, sy + 2, Pal.YELLOW)
				c.px(bx + 3, sy + 2, Pal.YELLOW)
				c.hline(bx, sy + 4, 5, Pal.RUST)
				g.rect(bx, sy + 2, 5, 2, Pal.OCHRE)
		_:
			for k in 4:
				var bx := wl + 5 + k * 5
				c.vline(bx + 1, sy + 1, 1, Pal.SKY)
				c.rect(bx, sy + 2, 3, 3, Pal.TEAL)
				c.px(bx, sy + 2, Pal.WATER)
				g.rect(bx, sy + 2, 3, 3, Pal.WATER)
	g.frame(wl + 2, sy, ww - 4, 6, Pal.a(Pal.OCHRE, 0.25))
	ix = ix

	# Markise mit Streifen und Bogenkante
	var ay := sy + 7
	for x in range(wl - 1, wl + ww + 1):
		var stripe := ((x - wl + 1) / 2) % 2 == 0
		var col: Color = awning if stripe else Pal.BONE
		c.vline(x, ay, 4, col)
		c.px(x, ay, Shade.light(col))
		if x % 2 == 0:
			c.px(x, ay + 4, Shade.dark(col))
	c.dither(wl, ay + 5, ww, 2, Pal.BLACK, 0.5)

	# Schaufenster mit Regalen
	var wy := ay + 6
	var wx := wl + 2
	var www := 15
	var wwh := bottom - wy - 1
	c.rect(wx - 1, wy - 1, www + 2, wwh + 2, Pal.STONE_D)
	c.rect(wx, wy, www, wwh, Pal.BLUE_D)
	g.rect(wx, wy, www, wwh, Pal.a(Pal.YELLOW, 0.8))
	for shelf in [wy + 3, wy + 7]:
		if shelf >= wy + wwh:
			continue
		c.hline(wx, shelf, www, Pal.WOOD)
		for x in range(wx, wx + www):
			if rng.randf() < 0.75:
				var goods: Color = _pick(rng, [Pal.BRICK_L, Pal.OCHRE, Pal.TEAL, Pal.YELLOW, Pal.ROSE, Pal.GRASS_L, Pal.BONE])
				c.px(x, shelf - 1, goods)
				if rng.randf() < 0.5:
					c.px(x, shelf - 2, Shade.dark(goods))
				g.px(x, shelf - 1, goods)
	c.line(wx + 2, wy, wx, wy + 2, Pal.SKY)
	c.line(wx + 7, wy, wx + 3, wy + 4, Pal.a(Pal.SKY, 0.7))
	c.vline(wx + www / 2, wy, wwh, Pal.STONE_D)
	g.clear(wx + www / 2, wy, 1, wwh)
	# Glastür
	var dx := wx + www + 2
	c.rect(dx - 1, wy - 1, 7, bottom - wy + 1, Pal.STONE_D)
	c.rect(dx, wy, 5, bottom - wy - 1, Pal.TEAL_D)
	c.px(dx, wy, Pal.SKY)
	c.px(dx + 1, wy, Pal.WATER)
	c.vline(dx + 3, wy + 4, 3, Pal.STONE_L)
	g.rect(dx, wy, 5, bottom - wy - 1, Pal.a(Pal.OCHRE, 0.8))
	c.hline(dx - 1, bottom, 7, Pal.STONE_L)
	# Sockel
	c.hline(wl, bottom, dx - wl - 1, Pal.STONE)

	c.outline(Pal.NIGHT)

	# Kisten mit Obst und Aufsteller vor dem Laden
	c.rect(wl, 58, 6, 4, Pal.WOOD)
	c.hline(wl, 58, 6, Pal.WOOD_L)
	c.vline(wl + 5, 58, 4, Pal.SOIL)
	for x in range(wl, wl + 6):
		c.px(x, 57, _pick(rng, [Pal.BRICK_L, Pal.GRASS_L, Pal.OCHRE, Pal.YELLOW]))
	c.hline(wl, 60, 6, Pal.SOIL)
	var sx := wl + ww - 5
	c.line(sx, 62, sx + 2, 57, Pal.WOOD)
	c.line(sx + 4, 62, sx + 2, 57, Pal.SOIL)
	c.rect(sx + 1, 58, 3, 3, Pal.NIGHT)
	c.px(sx + 2, 59, Pal.WHITE)
	return _result(c, g, meta)


# Fabrik

static func factory(variant: int, material: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = variant
	var c := PixelCanvas.new(64, 96)
	var g := PixelCanvas.new(64, 96)
	var meta := {"smoke": [], "blink": []}
	var wall: Color = Pal.BRICK if material == "ziegel" else Pal.STONE
	var wl := 3
	var ww := 58
	var bottom := 89
	var top := 64
	var wh := bottom - top + 1

	# Silo hinten links
	var silo_x := 5
	c.rect(silo_x, 24, 12, 30, Pal.STONE_L)
	for x in range(silo_x, silo_x + 12):
		var t := float(x - silo_x) / 11.0
		var col := Pal.WHITE if t < 0.2 else (Pal.STONE_L if t < 0.6 else (Pal.STONE if t < 0.85 else Pal.STONE_D))
		c.vline(x, 24, 30, col)
	for y in range(28, 54, 6):
		c.hline(silo_x, y, 12, Pal.STONE)
	c.ellipse(silo_x + 6, 24, 6, 2, Pal.STONE)
	c.ellipse(silo_x + 6, 24, 4.5, 1.2, Pal.STONE_L)
	c.vline(silo_x + 13, 22, 30, Pal.STONE_D)
	for y in range(23, 52, 2):
		c.px(silo_x + 14, y, Pal.STONE_D)
	# Rohr vom Silo zur Halle
	c.hline(silo_x + 12, 34, 8, Pal.RUST)
	c.hline(silo_x + 12, 35, 8, Pal.SOIL)

	# Schornstein hinten rechts
	var chx := 49
	for y in range(3, 50):
		var wv := 6 + (y - 3) / 18
		var x0 := chx - wv / 2
		for x in range(x0, x0 + wv):
			var t := float(x - x0) / float(wv - 1)
			var col := Pal.BRICK_L if t < 0.25 else (Pal.BRICK if t < 0.75 else Pal.BRICK_D)
			if (y % 3 == 0) and ((x + y / 3) % 3 == 0):
				col = Pal.BRICK_D
			c.px(x, y, col)
	for band in [12, 13, 30, 31]:
		c.hline(chx - 3, band, 7, Pal.BONE if band % 2 == 0 else Pal.STONE_L)
	c.rect(chx - 4, 2, 8, 2, Pal.STONE_D)
	c.hline(chx - 4, 2, 8, Pal.STONE)
	c.dither(chx - 3, 4, 6, 4, Pal.BLACK, 0.5)
	c.hline(chx - 2, 2, 4, Pal.BLACK)
	meta.smoke.append(Vector2(chx, 1))
	meta.blink.append(Vector2(chx + 3, 3))

	# Sheddach: Blechflächen steigen nach hinten an, dazwischen dunkle Glasbänder
	var rt := 40
	for tooth in 4:
		var ty := rt + tooth * 6
		# Glasband mit Sprossen
		c.rect(wl, ty, ww, 2, Pal.BLUE_D)
		for x in range(wl + 2, wl + ww, 7):
			c.vline(x, ty, 2, Pal.SLATE)
		c.px(wl + 5 + tooth * 11, ty, Pal.SKY)
		c.px(wl + 6 + tooth * 11, ty, Pal.BLUE)
		g.rect(wl, ty, ww, 2, Pal.a(Pal.YELLOW, 0.5))
		for x in range(wl + 2, wl + ww, 7):
			g.clear(x, ty, 1, 2)
		# Blech: oben im Licht, unten im Schatten der nächsten Reihe
		var ramp := [Pal.STONE_L, Pal.STONE_L, Pal.STONE, Pal.STONE_D]
		for r in 4:
			var yy := ty + 2 + r
			for x in range(wl, wl + ww):
				var col: Color = ramp[r]
				if x % 3 == 0 and r < 3:
					col = Shade.dark(col)
				c.px(x, yy, col)
		# Wenige Roststreifen am Blech
		for n in 2:
			var rx := wl + rng.randi_range(2, ww - 3)
			c.px(rx, ty + 4, Pal.RUST)
			c.px(rx, ty + 5, Pal.SOIL)
		# Seitenansicht als Sägezahn
		c.px(wl - 1, ty + 5, Pal.STONE_D)
		c.px(wl - 1, ty + 4, Pal.STONE_D)
	c.dither(wl + ww - 4, rt, 4, 24, Pal.STONE_D, 0.5)
	# Schornstein und Silo liegen hinter dem Dach; der Dachrand vorne
	c.rect(wl - 1, top - 2, ww + 2, 2, Shade.light(wall))
	c.hline(wl - 1, top - 1, ww + 2, Shade.dark(wall))

	# Halle
	_wall(c, rng, wl, top, ww, wh, wall, "stahl" if material == "stahl" else "ziegel")
	if material == "stahl":
		for n in 8:
			var rx := wl + rng.randi_range(2, ww - 3)
			c.vline(rx, top + rng.randi_range(0, 6), rng.randi_range(2, 6), Pal.RUST)
	# Hohe Fensterbänder
	for wx in [wl + 3, wl + 11, wl + 41, wl + 49]:
		var fx: int = wx
		c.rect(fx, top + 4, 6, 9, Pal.STONE_D)
		c.rect(fx + 1, top + 5, 4, 7, Pal.BLUE_D)
		c.hline(fx + 1, top + 8, 4, Pal.STONE_D)
		c.vline(fx + 3, top + 5, 7, Pal.STONE_D)
		c.px(fx + 1, top + 5, Pal.SKY)
		g.rect(fx + 1, top + 5, 2, 3, Pal.YELLOW)
		g.rect(fx + 4, top + 5, 1, 3, Pal.YELLOW)
		g.rect(fx + 1, top + 9, 2, 3, Pal.OCHRE)
		g.rect(fx + 4, top + 9, 1, 3, Pal.OCHRE)
		c.hline(fx, top + 13, 6, Pal.STONE_L)
	# Rolltor
	var dx := wl + 20
	var dw := 17
	c.rect(dx - 1, top + 6, dw + 2, wh - 6, Pal.STONE_D)
	for y in range(top + 7, bottom + 1):
		c.hline(dx, y, dw, Pal.STONE_L if (y % 2 == 0) else Pal.STONE)
	c.dither(dx, top + 7, dw, 3, Pal.SLATE, 0.5)
	c.hline(dx, bottom - 1, dw, Pal.STONE_D)
	for x in range(dx - 1, dx + dw + 1):
		c.px(x, top + 5, Pal.YELLOW if (x / 2) % 2 == 0 else Pal.BLACK)
	# Nummer an der Wand
	_digits(c, dx + dw / 2 - 1, top + 1, str(rng.randi_range(1, 9)), Pal.BONE)
	# Kleine Tür mit Lampe
	var px_ := wl + 42
	c.rect(px_ - 1, bottom - 10, 7, 11, Pal.STONE_D)
	c.rect(px_, bottom - 9, 5, 10, Pal.TEAL_D)
	c.vline(px_, bottom - 9, 10, Pal.TEAL)
	c.px(px_ + 3, bottom - 4, Pal.YELLOW)
	c.rect(px_ + 1, bottom - 13, 3, 1, Pal.STONE_D)
	c.hline(px_ + 1, bottom - 12, 3, Pal.YELLOW)
	g.hline(px_ + 1, bottom - 12, 3, Pal.WHITE)
	g.rect(px_, bottom - 11, 5, 2, Pal.a(Pal.YELLOW, 0.35))
	# Rohre an der Wand
	c.vline(wl + ww - 4, top + 2, wh - 2, Pal.STONE_L)
	c.vline(wl + ww - 3, top + 2, wh - 2, Pal.STONE_D)
	c.hline(wl + ww - 5, top + 10, 3, Pal.STONE_D)
	c.hline(wl + ww - 5, top + 20, 3, Pal.STONE_D)

	c.outline(Pal.NIGHT)

	# Hof: Betonplatte, Warnstreifen, Fässer und Paletten
	c.rect(dx - 2, bottom + 1, dw + 4, 5, Pal.STONE_L)
	c.hline(dx - 2, bottom + 1, dw + 4, Pal.STONE)
	for x in range(dx - 2, dx + dw + 2):
		var s := (x + 96) % 4
		c.px(x, bottom + 5, Pal.YELLOW if s < 2 else Pal.NIGHT)
	for k in 3:
		var bx := wl + 2 + k * 4
		var col: Color = _pick(rng, [Pal.RUST, Pal.TEAL, Pal.BLUE, Pal.BRICK])
		c.rect(bx, bottom + 1, 3, 4, col)
		c.vline(bx, bottom + 1, 4, Shade.light(col))
		c.hline(bx, bottom + 2, 3, Shade.dark(col))
		c.hline(bx, bottom + 1, 3, Shade.light(Shade.light(col)))
	for k in 2:
		var px2 := wl + ww - 12 + k * 6
		c.rect(px2, bottom + 4, 5, 1, Pal.WOOD)
		c.rect(px2, bottom + 1, 5, 3, Pal.WOOD_L)
		c.frame(px2, bottom + 1, 5, 3, Pal.WOOD)
		c.line(px2, bottom + 1, px2 + 4, bottom + 3, Pal.WOOD)
	return _result(c, g, meta)


# Kraftwerk

static func power_plant(variant: int, _material: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = variant
	var c := PixelCanvas.new(64, 112)
	var g := PixelCanvas.new(64, 112)
	var meta := {"smoke": [], "blink": []}

	# Kühlturm hinten links
	var cx := 17.0
	var base_y := 88
	var top_y := 26
	for y in range(top_y, base_y + 1):
		var t := float(base_y - y) / float(base_y - top_y)
		var r := 0.0
		if t < 0.72:
			var u := (t - 0.72) / 0.72
			r = 9.0 + 5.0 * u * u
		else:
			r = 9.0 + (t - 0.72) / 0.28 * 1.6
		var x0 := int(round(cx - r))
		var x1 := int(round(cx + r))
		for x in range(x0, x1 + 1):
			var s := float(x - x0) / maxf(1.0, float(x1 - x0))
			var col := Pal.STONE
			if s < 0.1:
				col = Pal.STONE_L
			elif s < 0.32:
				col = Pal.BONE
			elif s < 0.36:
				col = Pal.BONE if (y % 2 == 0) else Pal.STONE_L
			elif s < 0.6:
				col = Pal.STONE_L
			elif s < 0.64:
				col = Pal.STONE_L if (y % 2 == 0) else Pal.STONE
			elif s < 0.88:
				col = Pal.STONE
			else:
				col = Pal.STONE_D
			# Betonringe und Wetterspuren
			if y % 11 == 0:
				col = Shade.dark(col)
			elif y > base_y - 8 and (x + y) % 3 == 0:
				col = Shade.dark(col)
			c.px(x, y, col)
	# Öffnung oben
	c.ellipse(cx, top_y + 1, 10.6, 2.6, Pal.STONE_L)
	c.ellipse(cx, top_y + 1, 9.2, 1.8, Pal.NIGHT)
	c.hline(int(cx) - 6, top_y + 2, 12, Pal.SLATE)
	# Stützen am Fuß
	for x in range(int(cx) - 13, int(cx) + 14):
		if x % 2 == 0:
			c.vline(x, base_y - 2, 3, Pal.NIGHT)
		else:
			c.vline(x, base_y - 2, 3, Pal.STONE_D)
	c.hline(int(cx) - 14, base_y + 1, 29, Pal.STONE_D)
	meta.smoke.append(Vector2(cx, top_y))
	meta.blink.append(Vector2(cx + 9, top_y))

	# Turbinenhalle rechts
	var hx := 31
	var hw := 31
	var bottom := 103
	var htop := 78
	var rt := 62
	c.rect(hx, rt, hw, htop - rt, Pal.STONE_D)
	c.speckle(hx, rt, hw, htop - rt, Pal.SLATE, 0.2, rng)
	for k in 3:
		var sx := hx + 4 + k * 9
		c.rect(sx, rt + 4, 6, 8, Pal.BLUE)
		c.frame(sx, rt + 4, 6, 8, Pal.STONE_L)
		c.px(sx + 1, rt + 5, Pal.SKY)
		c.hline(sx + 1, rt + 8, 4, Pal.STONE_L)
		g.rect(sx + 1, rt + 5, 4, 6, Pal.a(Pal.YELLOW, 0.5))
	c.rect(hx - 1, rt - 1, hw + 2, 2, Pal.STONE_L)
	c.rect(hx - 1, htop - 2, hw + 2, 2, Pal.STONE_L)
	c.hline(hx - 1, htop - 1, hw + 2, Pal.STONE)
	_wall(c, rng, hx, htop, hw, bottom - htop + 1, Pal.STONE_L, "beton")
	c.rect(hx, htop + 4, hw, 2, Pal.TEAL)
	c.hline(hx, htop + 4, hw, Pal.WATER)
	# Fensterband
	c.rect(hx + 2, htop + 8, hw - 4, 4, Pal.BLUE_D)
	for x in range(hx + 2, hx + hw - 2, 4):
		c.vline(x, htop + 8, 4, Pal.STONE_D)
	c.px(hx + 3, htop + 8, Pal.SKY)
	g.rect(hx + 3, htop + 8, hw - 6, 4, Pal.YELLOW)
	for x in range(hx + 2, hx + hw - 2, 4):
		g.clear(x, htop + 8, 1, 4)
	# Tor
	c.rect(hx + 18, htop + 14, 10, bottom - htop - 13, Pal.STONE_D)
	for y in range(htop + 15, bottom + 1, 2):
		c.hline(hx + 19, y, 8, Pal.STONE)
	# Warnschild
	c.poly(PackedVector2Array([Vector2(hx + 7, htop + 21), Vector2(hx + 10.5, htop + 14), Vector2(hx + 14, htop + 21)]), Pal.YELLOW)
	c.line(hx + 10, htop + 16, hx + 11, htop + 18, Pal.BLACK)
	c.line(hx + 11, htop + 18, hx + 10, htop + 20, Pal.BLACK)

	c.outline(Pal.NIGHT)

	# Umspannwerk vorne links: Kies, Trafos, Zaun
	var yx := 2
	var yy := 91
	c.rect(yx, yy, 28, 17, Pal.STONE_D)
	c.speckle(yx, yy, 28, 17, Pal.STONE, 0.3, rng)
	c.speckle(yx, yy, 28, 17, Pal.SLATE, 0.2, rng)
	for k in 2:
		var tx := yx + 4 + k * 12
		c.rect(tx, yy + 4, 8, 8, Pal.STONE)
		c.hline(tx, yy + 4, 8, Pal.STONE_L)
		for fx in range(tx, tx + 8, 2):
			c.vline(fx, yy + 6, 6, Pal.SLATE)
		c.vline(tx + 7, yy + 4, 8, Pal.STONE_D)
		for ix in [tx + 1, tx + 4, tx + 6]:
			c.vline(ix, yy + 1, 3, Pal.BONE)
			c.px(ix, yy + 2, Pal.STONE_L)
		c.rect(tx, yy + 12, 8, 1, Pal.NIGHT)
	# Leitung zur Halle
	c.line(yx + 6, yy + 1, hx + 2, htop + 2, Pal.NIGHT)
	c.line(yx + 18, yy + 1, hx + 2, htop + 3, Pal.NIGHT)
	# Zaun
	for x in range(yx, yx + 28):
		c.px(x, yy - 1, Pal.STONE_L if x % 2 == 0 else Pal.STONE)
		c.px(x, yy + 16, Pal.STONE_L if x % 2 == 0 else Pal.STONE)
		if x % 6 == 0:
			c.vline(x, yy - 3, 3, Pal.STONE_D)
			c.vline(x, yy + 13, 4, Pal.STONE_D)
	c.vline(yx, yy - 1, 18, Pal.STONE)
	return _result(c, g, meta)


# Wasserturm

static func water_tower(variant: int, _material: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = variant
	var c := PixelCanvas.new(32, 96)
	var g := PixelCanvas.new(32, 96)
	var meta := {"smoke": [], "blink": []}
	var paint: Color = _pick(rng, [Pal.TEAL, Pal.STONE_L, Pal.WATER, Pal.BRICK_L, Pal.SKY])
	var lt := Shade.light(paint)
	var dk := Shade.dark(paint)
	var bottom := 90

	# Hintere Beine
	for lx in [10, 21]:
		c.vline(lx, 50, bottom - 6 - 50, Pal.SLATE)
	# Steigrohr
	c.rect(15, 50, 2, bottom - 50, Pal.STONE)
	c.vline(15, 50, bottom - 50, Pal.STONE_L)
	# Vordere Beine mit Kreuzverstrebung
	var legs := [6, 25]
	for lx in legs:
		c.rect(lx, 50, 2, bottom - 50 + 1, Pal.STONE_D)
		c.vline(lx, 50, bottom - 50 + 1, Pal.STONE)
	for k in 3:
		var y0 := 54 + k * 12
		c.line(8, y0, 24, y0 + 11, Pal.STONE_D)
		c.line(24, y0, 8, y0 + 11, Pal.STONE_D)
		c.hline(8, y0, 17, Pal.STONE)
	# Leiter am linken Bein
	c.vline(3, 52, bottom - 52, Pal.STONE_L)
	c.vline(5, 52, bottom - 52, Pal.STONE_L)
	for y in range(53, bottom, 2):
		c.px(4, y, Pal.STONE)

	# Behälter
	var tx := 3
	var tw := 26
	var t_top := 30
	var t_bot := 50
	for x in range(tx, tx + tw):
		var s := float(x - tx) / float(tw - 1)
		var col := paint
		if s < 0.15:
			col = lt
		elif s < 0.3 and PixelCanvas.bayer(x, 0, 0.5):
			col = lt
		elif s > 0.85:
			col = dk
		elif s > 0.68 and PixelCanvas.bayer(x, 1, 0.5):
			col = dk
		c.vline(x, t_top, t_bot - t_top, col)
	# Boden als Schale
	c.ellipse(16, t_bot, 13, 4, dk)
	c.ellipse(15, t_bot - 1, 12, 3, paint)
	c.rect(tx, t_top, tw, t_bot - t_top - 1, Pal.a(Color.WHITE, 0.0))
	for x in range(tx, tx + tw):
		var s2 := float(x - tx) / float(tw - 1)
		c.vline(x, t_top, t_bot - t_top - 1, lt if s2 < 0.15 else (dk if s2 > 0.85 else c.get_px(x, t_top)))
	# Nähte
	for x in range(tx + 4, tx + tw - 1, 6):
		c.vline(x, t_top + 1, t_bot - t_top - 2, Shade.dark(c.get_px(x, t_top + 2)))
	c.hline(tx, t_top + 9, tw, Shade.dark(paint))
	# Tropfen-Symbol
	var dxp := 14
	c.px(dxp + 1, 36, Pal.WHITE)
	c.hline(dxp, 37, 3, Pal.WHITE)
	c.rect(dxp - 1, 38, 5, 2, Pal.WHITE)
	c.hline(dxp, 40, 3, Pal.WHITE)
	c.px(dxp, 38, Pal.SKY)
	# Kegeldach
	c.poly(PackedVector2Array([Vector2(1, t_top + 1), Vector2(16, t_top - 11), Vector2(31, t_top + 1)]), Pal.STONE_D)
	c.poly(PackedVector2Array([Vector2(1, t_top + 1), Vector2(16, t_top - 11), Vector2(16, t_top + 1)]), Pal.STONE)
	for y in range(t_top - 10, t_top + 1, 3):
		c.hline(2, y, 28, Pal.a(Pal.SLATE, 0.0))
	c.line(1, t_top, 16, t_top - 12, Pal.STONE_L)
	c.hline(1, t_top + 1, 30, Pal.SLATE)
	c.vline(16, t_top - 15, 4, Pal.STONE_D)
	c.px(16, t_top - 16, Pal.BRICK_L)
	meta.blink.append(Vector2(16, t_top - 16))
	# Laufsteg mit Geländer
	c.hline(0, t_bot + 2, 32, Pal.STONE_D)
	c.hline(0, t_bot - 2, 32, Pal.STONE_L)
	for x in range(0, 32, 4):
		c.vline(x, t_bot - 2, 4, Pal.STONE_L)

	c.outline(Pal.NIGHT)

	# Fundamente
	for lx in legs:
		c.rect(lx - 1, bottom + 1, 4, 2, Pal.STONE_L)
		c.hline(lx - 1, bottom + 2, 4, Pal.STONE)
	c.rect(14, bottom + 1, 4, 2, Pal.STONE_L)
	return _result(c, g, meta)


# Park

static func park(variant: int, _material: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = variant
	var c := PixelCanvas.new(32, 64)
	var g := PixelCanvas.new(32, 64)
	var meta := {"smoke": [], "blink": [], "lamp": []}
	var kind: int = rng.randi() % 3
	# Rasen mit Mähstreifen
	for y in range(33, 63):
		for x in range(1, 31):
			var col := Pal.GRASS_L if ((x / 4) % 2 == 0) else Pal.GRASS
			if PixelCanvas.bayer(x, y, 0.12):
				col = Pal.LEAF_L if col == Pal.GRASS_L else Pal.GRASS_L
			c.px(x, y, col)
	# Hecke als Rand
	for x in range(1, 31):
		c.px(x, 33, Pal.MOSS)
		c.px(x, 62, Pal.MOSS)
	for y in range(33, 63):
		c.px(1, y, Pal.MOSS)
		c.px(30, y, Pal.MOSS_D)
	match kind:
		0:
			# Weg, Baum, Bank, Beet
			for t in 40:
				var f := t / 39.0
				var px_ := lerpf(4.0, 28.0, f)
				var py := 60.0 - f * 22.0 + sin(f * PI * 2.0) * 3.0
				c.rect(int(px_) - 1, int(py) - 1, 4, 3, Pal.SAND)
			c.speckle(2, 34, 28, 28, Pal.WOOD_L, 0.0, rng)
			_bench(c, 19, 52)
			_flowerbed(c, rng, 4, 54, 9, 5)
			_tree(c, rng, 10, 38, 11.0)
			_lamp(c, g, 26, 46, meta)
		1:
			# Brunnen mit Wegkreuz
			c.rect(14, 34, 4, 28, Pal.SAND)
			c.rect(2, 46, 28, 4, Pal.SAND)
			c.ellipse(16, 48, 9, 6, Pal.STONE_L)
			c.ellipse(16, 48, 7.5, 4.8, Pal.STONE)
			c.ellipse(16, 48.5, 6.5, 4, Pal.WATER)
			c.ellipse(15, 47.5, 4, 2, Pal.SKY)
			c.ellipse(16, 49, 5, 2.5, Pal.TEAL)
			c.rect(15, 42, 2, 6, Pal.STONE_L)
			c.px(15, 41, Pal.WHITE)
			c.px(16, 41, Pal.SKY)
			c.px(14, 43, Pal.SKY)
			c.px(17, 43, Pal.SKY)
			meta["fountain"] = Vector2(16, 41)
			for p in [Vector2(5, 38), Vector2(26, 38), Vector2(5, 57), Vector2(26, 57)]:
				_bush(c, rng, int(p.x), int(p.y))
			_lamp(c, g, 22, 40, meta)
		_:
			# Spielplatz: Sandkasten, Schaukel, kleiner Baum
			c.rect(3, 50, 12, 10, Pal.SAND)
			c.frame(3, 50, 12, 10, Pal.WOOD)
			c.hline(3, 50, 12, Pal.WOOD_L)
			c.speckle(4, 51, 10, 8, Pal.OCHRE, 0.1, rng)
			c.px(7, 54, Pal.BRICK_L)
			c.px(8, 54, Pal.BRICK_L)
			c.px(11, 56, Pal.BLUE)
			# Schaukel
			c.line(17, 58, 20, 41, Pal.WOOD)
			c.line(23, 58, 20, 41, Pal.WOOD)
			c.line(24, 58, 27, 41, Pal.WOOD)
			c.line(30, 58, 27, 41, Pal.WOOD_L)
			c.hline(20, 41, 8, Pal.WOOD_L)
			c.hline(20, 42, 8, Pal.SOIL)
			for sx in [22, 25]:
				c.vline(sx, 43, 9, Pal.STONE)
				c.vline(sx + 1, 43, 9, Pal.STONE)
			c.rect(21, 52, 4, 1, Pal.BRICK)
			c.rect(24, 52, 3, 1, Pal.BLUE)
			_tree(c, rng, 8, 38, 8.0)
	c.outline(Pal.MOSS_D)
	return _result(c, g, meta)


static func _bench(c: PixelCanvas, x: int, y: int) -> void:
	c.hline(x, y, 9, Pal.WOOD_L)
	c.hline(x, y + 1, 9, Pal.WOOD)
	c.hline(x, y - 3, 9, Pal.WOOD_L)
	c.hline(x, y - 2, 9, Pal.WOOD)
	c.vline(x + 1, y - 3, 6, Pal.STONE_D)
	c.vline(x + 7, y - 3, 6, Pal.STONE_D)


static func _flowerbed(c: PixelCanvas, rng: RandomNumberGenerator, x: int, y: int, fw: int, fh: int) -> void:
	c.rect(x, y, fw, fh, Pal.SOIL)
	c.hline(x, y + fh - 1, fw, Pal.SOIL_D)
	for yy in range(y, y + fh - 1):
		for xx in range(x, x + fw):
			if (xx + yy) % 2 == 0:
				c.px(xx, yy, Pal.GRASS)
			if rng.randf() < 0.35:
				c.px(xx, yy, _pick(rng, [Pal.ROSE, Pal.YELLOW, Pal.WHITE, Pal.BRICK_L, Pal.BLUE]))


static func _bush(c: PixelCanvas, rng: RandomNumberGenerator, x: int, y: int) -> void:
	c.disc(x, y, 3, Pal.MOSS)
	c.disc(x - 0.5, y - 0.5, 2, Pal.GRASS)
	c.px(x - 1, y - 2, Pal.GRASS_L)
	if rng.randf() < 0.5:
		c.px(x + 1, y, Pal.ROSE)


static func _tree(c: PixelCanvas, rng: RandomNumberGenerator, x: int, y: int, r: float) -> void:
	c.rect(x - 1, y, 3, int(r) + 2, Pal.WOOD)
	c.vline(x + 1, y, int(r) + 2, Pal.SOIL)
	NatureArt.crown(c, rng, Vector2(x + 0.5, y - r * 0.55), r, r * 0.85)


static func _lamp(c: PixelCanvas, g: PixelCanvas, x: int, y: int, meta: Dictionary) -> void:
	c.vline(x, y - 12, 13, Pal.STONE_D)
	c.px(x, y + 1, Pal.SLATE)
	c.hline(x - 1, y + 1, 3, Pal.STONE_D)
	c.rect(x - 1, y - 14, 3, 2, Pal.YELLOW)
	c.hline(x - 1, y - 15, 3, Pal.STONE_D)
	g.rect(x - 1, y - 14, 3, 2, Pal.WHITE)
	g.disc(x, y - 13, 3, Pal.a(Pal.YELLOW, 0.35))
	meta.lamp.append(Vector2(x, y))


## Kleine Ziffern 3x5 für Hausnummern und Schilder.
static func _digits(c: PixelCanvas, x: int, y: int, text: String, col: Color) -> void:
	const D := {
		"0": ["###", "#.#", "#.#", "#.#", "###"], "1": [".#.", "##.", ".#.", ".#.", "###"],
		"2": ["##.", "..#", ".#.", "#..", "###"], "3": ["##.", "..#", ".#.", "..#", "##."],
		"4": ["#.#", "#.#", "###", "..#", "..#"], "5": ["###", "#..", "##.", "..#", "##."],
		"6": [".##", "#..", "###", "#.#", "###"], "7": ["###", "..#", ".#.", ".#.", ".#."],
		"8": ["###", "#.#", "###", "#.#", "###"], "9": ["###", "#.#", "###", "..#", "##."],
	}
	var cx := x
	for ch in text:
		var rows: Array = D.get(ch, [])
		for ry in rows.size():
			for rx in 3:
				if rows[ry][rx] == "#":
					c.px(cx + rx, y + ry, col)
		cx += 4


static func make(type: String, variant: int, material: String) -> Dictionary:
	match type:
		"house": return house(variant, material)
		"shop": return shop(variant, material)
		"factory": return factory(variant, material)
		"power_plant": return power_plant(variant, material)
		"water_tower": return water_tower(variant, material)
		"park": return park(variant, material)
	return house(variant, material)
