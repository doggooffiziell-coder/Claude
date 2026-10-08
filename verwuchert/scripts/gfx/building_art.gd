class_name BuildingArt
extends RefCounted
## Malt alle Gebäude isometrisch: linke Wand im Licht, rechte Wand im Schatten, Dach oben.
## Jedes Gebäude bekommt ein Farbbild und ein Leuchtbild für die Nacht.
## Das Bild sitzt mit der unteren Ecke auf der unteren Ecke seiner Felder.
## facing sagt, an welcher Wand die Tür liegt: "left" (nach links unten), "right" oder "back".

const GLASS_GLOW := Pal.YELLOW
const GLOW_EDGE := Pal.OCHRE
const CLEAR := Color(0, 0, 0, 0)


static func _result(p: IsoPainter, meta: Dictionary, w: int, h: int) -> Dictionary:
	var top := 0
	var found := false
	for y in p.c.h:
		for x in p.c.w:
			if p.c.img.get_pixel(x, y).a > 0.0:
				found = true
				break
		if found:
			top = y
			break
	meta["top"] = top
	meta["tex"] = p.c.texture()
	meta["img"] = p.c.img
	meta["glow"] = p.g.texture()
	meta["size"] = Vector2i(p.c.w, p.c.h)
	# Ankerpunkt: untere Ecke der Fläche im Bild
	meta["anchor"] = p.P(w, h, 0)
	return meta


static func _pick(rng: RandomNumberGenerator, options: Array):
	return options[rng.randi() % options.size()]


static func _noise(a: int, b: int, seed_value: int) -> int:
	return absi(hash(Vector3i(a, b, seed_value))) % 1000


# Wandstruktur

## Farbe einer Wand an Spalte ax und Zeile uy (von unten). Ziegel im Verband, Holz als Bretter.
static func _wall_px(material: String, base: Color, ax: int, uy: int, seed_value: int) -> Color:
	var lt := Shade.light(base)
	var dk := Shade.dark(base)
	match material:
		"ziegel":
			if uy % 3 == 2:
				return dk
			var course := uy / 3
			if (ax + (course % 2) * 3) % 6 == 5:
				return dk
			var n := _noise((ax + (course % 2) * 3) / 6, course, seed_value)
			if n < 110:
				return lt
			if n < 170:
				return dk
			return base
		"holz":
			if uy % 3 == 0:
				return lt
			if uy % 3 == 2:
				return dk
			return dk if _noise(ax, uy, seed_value) < 30 else base
		"beton":
			if uy % 9 == 8 or ax % 9 == 8:
				return dk
			var n2 := _noise(ax, uy, seed_value)
			return lt if n2 < 40 else (dk if n2 < 70 else base)
		"stahl":
			var k := ax % 4
			if k == 0:
				return lt
			if k == 3:
				return dk
			return base
		"putz":
			var n3 := _noise(ax, uy, seed_value)
			return lt if n3 < 50 else (dk if n3 < 80 else base)
	return base


## Füllfunktion für eine Wand mit Fenstern, Türen und Struktur.
## features: Liste von Dictionaries mit kind, x, y, w, h in Pixeln der Wand (x von links, y von unten).
static func _facade(material: String, base: Color, cols: float, height: float, features: Array, shaded: bool, seed_value: int, trim := Color(0, 0, 0, 0)) -> Callable:
	return func(s: float, t: float, _x: int, _y: int):
		var ax := int(s * cols)
		var uy := int(t * height)
		if uy >= int(height):
			uy = int(height) - 1
		for f in features:
			var fx: int = f.x
			var fy: int = f.y
			var fw: int = f.w
			var fh: int = f.h
			if ax >= fx and ax < fx + fw and uy >= fy and uy < fy + fh:
				return _feature_px(f, ax - fx, uy - fy, shaded)
		var col := _wall_px(material, base, ax, uy, seed_value)
		# Sockel
		if uy < 2:
			col = Pal.STONE_D if uy == 0 else Pal.STONE
		# Kanten: Ecke vorne heller, oben Schatten der Traufe
		if trim.a > 0.0 and (ax == 0 or ax == int(cols) - 1) and uy >= 2:
			col = trim
		if uy >= int(height) - 2 and uy >= 2:
			col = Shade.dark(col)
		if shaded:
			col = Shade.dark(col)
		return col


## Ein Pixel eines Fensters, einer Tür oder eines Schildes.
static func _feature_px(f: Dictionary, x: int, y: int, shaded: bool) -> Variant:
	var w: int = f.w
	var h: int = f.h
	var frame: Color = f.get("frame", Pal.BONE)
	if shaded:
		frame = Shade.dark(frame)
	match f.kind:
		"window":
			if x == 0 or x == w - 1 or y == 0 or y == h - 1:
				return frame
			# Sprosse in der Mitte
			if h >= 6 and y == h / 2:
				return [frame, CLEAR]
			if w >= 6 and x == w / 2:
				return [frame, CLEAR]
			var top := y == h - 2
			var glass := Pal.BLUE if top else Pal.BLUE_D
			if top and x == 1:
				glass = Pal.SKY
			var cur: Color = f.get("curtain", Color(0, 0, 0, 0))
			if cur.a > 0.0 and x == w - 2 and y >= h - 4:
				return [Shade.dark(cur) if shaded else cur, GLOW_EDGE]
			return [glass, GLOW_EDGE if y == 1 else GLASS_GLOW]
		"door":
			var dc: Color = f.get("color", Pal.TEAL_D)
			if shaded:
				dc = Shade.dark(dc)
			if x == 0 or x == w - 1 or y == h - 1:
				return frame
			if x == w - 2 and y == h / 2:
				return Pal.YELLOW
			if y == h - 3 and x > 0 and x < w - 1:
				return [Pal.SKY if not shaded else Pal.BLUE, GLASS_GLOW]
			return Shade.dark(dc) if (x == 1) else dc
		"shop":
			# Schaufenster mit Regalen
			if x == 0 or x == w - 1 or y == h - 1 or y == 0:
				return Pal.STONE_D
			if y == 3 or y == 7:
				return [Pal.WOOD, Color(0, 0, 0, 0)]
			if (y == 4 or y == 8) and (x * 7 + y) % 3 != 0:
				var goods := [Pal.BRICK_L, Pal.OCHRE, Pal.TEAL, Pal.YELLOW, Pal.ROSE, Pal.GRASS_L]
				var gc: Color = goods[(x * 5 + y) % goods.size()]
				return [gc, gc]
			if y == h - 2 and x < 3:
				return [Pal.SKY, GLASS_GLOW]
			return [Pal.BLUE_D, Pal.a(Pal.YELLOW, 0.85)]
		"glassdoor":
			if x == 0 or x == w - 1 or y == h - 1:
				return Pal.STONE_D
			return [Pal.TEAL_D, Pal.a(Pal.OCHRE, 0.85)]
		"roller":
			if x == 0 or x == w - 1 or y == h - 1:
				return Pal.STONE_D
			return Pal.STONE_L if y % 2 == 0 else Pal.STONE
		"sign":
			var sc: Color = f.get("color", Pal.NIGHT)
			if y == h - 1 or y == 0:
				return Pal.WOOD
			var icon: Array = f.get("icon", [])
			for ip in icon:
				if ip.x == x and ip.y == y:
					return [ip.c, ip.c]
			return sc
		"band":
			return f.get("color", Pal.TEAL)
		"vent":
			return Pal.STONE_D if (x + y) % 2 == 0 else Pal.SLATE
	return Pal.WHITE


static func _window(x: int, y: int, w: int, h: int, rng: RandomNumberGenerator, frame := Pal.BONE) -> Dictionary:
	var cur: Color = Color(0, 0, 0, 0)
	if rng.randf() < 0.7:
		cur = _pick(rng, [Pal.ROSE, Pal.OCHRE, Pal.BONE, Pal.TEAL, Pal.SAND])
	return {"kind": "window", "x": x, "y": y, "w": w, "h": h, "frame": frame, "curtain": cur}


# Dächer

## Satteldach. axis "u": First läuft nach rechts unten, Giebel auf der rechten Wand.
## axis "v": First läuft nach links unten, Giebel auf der linken Wand.
static func _gable(p: IsoPainter, u0: float, v0: float, u1: float, v1: float, H: float, R: float, ov: float, axis: String, roof: Color, gable_fill: Callable, gable_fill_shaded: Callable) -> void:
	var lt := Shade.light(roof)
	var dk := Shade.dark(roof)
	if axis == "u":
		var vm := (v0 + v1) * 0.5
		var lu := u1 - u0 + ov * 2.0
		# Hintere Fläche: vom First nach hinten unten
		var back_len := (vm - (v0 - ov))
		p.quad(Vector3(u0 - ov, vm, H + R), Vector3(lu, 0, 0), Vector3(0, -back_len, -R), _shingles(dk, lu * 32.0, 12.0))
		# Giebeldreieck rechts
		p.quad(Vector3(u1, v1, H), Vector3(0, v0 - v1, 0), Vector3(0, vm - v1, R), gable_fill_shaded, true)
		# Vordere Fläche im Licht
		var front_len := (v1 + ov) - vm
		p.quad(Vector3(u0 - ov, v1 + ov, H - 1), Vector3(lu, 0, 0), Vector3(0, -front_len, R + 1), _shingles(roof, lu * 32.0, 14.0, lt))
		# Firstlinie
		p.line3(Vector3(u0 - ov, vm, H + R), Vector3(u1 + ov, vm, H + R), Shade.light(lt))
		# Ortgang rechts
		p.line3(Vector3(u1 + ov, v1 + ov, H - 1), Vector3(u1 + ov, vm, H + R), dk)
	else:
		var um := (u0 + u1) * 0.5
		var lv := v1 - v0 + ov * 2.0
		var back_len2 := um - (u0 - ov)
		# Hintere Fläche zeigt nach links oben: im Licht
		p.quad(Vector3(um, v1 + ov, H + R), Vector3(0, -lv, 0), Vector3(-back_len2, 0, -R), _shingles(lt, lv * 32.0, 12.0))
		# Giebeldreieck links
		p.quad(Vector3(u0, v1, H), Vector3(u1 - u0, 0, 0), Vector3(um - u0, 0, R), gable_fill, true)
		# Vordere Fläche zeigt nach rechts unten: Schatten
		var front_len2 := (u1 + ov) - um
		p.quad(Vector3(u1 + ov, v1 + ov, H - 1), Vector3(0, -lv, 0), Vector3(-front_len2, 0, R + 1), _shingles(dk, lv * 32.0, 14.0))
		p.line3(Vector3(um, v1 + ov, H + R), Vector3(um, v0 - ov, H + R), lt)
		p.line3(Vector3(u0 - ov, v1 + ov, H - 1), Vector3(um, v1 + ov, H + R), Shade.light(lt))


## Schindeln: Reihen parallel zur Traufe, versetzte Fugen, nach oben heller.
static func _shingles(base: Color, cols: float, rows: float, top_col := Color(0, 0, 0, 0)) -> Callable:
	var dk := Shade.dark(base)
	return func(s: float, t: float, _x: int, _y: int):
		var ax := int(s * cols)
		var ry := int(t * rows)
		if ry % 3 == 0:
			return dk
		var course := ry / 3
		if ry % 3 == 1 and (ax + course * 2) % 4 == 0:
			return dk
		if top_col.a > 0.0 and t > 0.72 and PixelCanvas.bayer(ax, ry, (t - 0.72) * 3.0):
			return top_col
		return base


## Flachdach mit Brüstung, Teerpappe und Kies.
static func _flat_roof(p: IsoPainter, u0: float, v0: float, u1: float, v1: float, H: float, edge: Color, seed_value: int) -> void:
	p.ground(u0, v0, u1, v1, H, func(s, t, x, y):
		var e := 0.06
		if s < e or t < e or s > 1.0 - e or t > 1.0 - e:
			return Shade.light(edge) if (s < e or t < e) else edge
		var n := _noise(x, y, seed_value)
		return Pal.STONE_D if n < 220 else (Pal.STONE if n < 260 else Pal.SLATE))


## Schornstein als kleine Kiste aus Ziegeln mit dunkler Öffnung.
static func _chimney(p: IsoPainter, u: float, v: float, z0: float, z1: float, meta: Dictionary) -> void:
	var s := 0.055
	p.box(u - s, v - s, u + s, v + s, z0, z1, Pal.BRICK, Pal.BRICK_D, Pal.STONE)
	var top := p.P(u, v, z1)
	p.c.px(int(top.x), int(top.y), Pal.BLACK)
	p.c.px(int(top.x) - 1, int(top.y), Pal.NIGHT)
	meta.smoke.append(p.P(u, v, z1 + 1))


# Wohnhaus

static func house(variant: int, material: String, facing: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = variant
	var p := IsoPainter.for_footprint(1, 1, 50)
	var meta := {"smoke": [], "blink": []}
	var style: String = _pick(rng, ["gable_u", "gable_v", "tall", "gable_u", "gable_v"])
	if material == "holz" and style == "tall":
		style = "gable_v"
	var roof: Color = _pick(rng, [Pal.BRICK_D, Pal.SLATE, Pal.TEAL_D, Pal.PLUM, Pal.SOIL, Pal.STONE_D, Pal.BRICK])
	var wall: Color = Pal.BRICK
	var mat := material
	if material == "holz":
		wall = _pick(rng, [Pal.WOOD, Pal.TEAL, Pal.SAND, Pal.STONE_L, Pal.BLUE, Pal.WOOD_L])
	elif style == "tall" and rng.randf() < 0.4:
		wall = _pick(rng, [Pal.SAND, Pal.BONE, Pal.ROSE, Pal.SKY])
		mat = "putz"
	var trim := Pal.BONE if material == "holz" else Color(0, 0, 0, 0)
	var door_col: Color = _pick(rng, [Pal.TEAL_D, Pal.BRICK_D, Pal.BLUE_D, Pal.WOOD, Pal.MOSS, Pal.PLUM])
	var u0 := 0.2
	var u1 := 0.8
	var v0 := 0.2
	var v1 := 0.8
	var H := 26.0 if style == "tall" else 16.0
	var cols := (u1 - u0) * 32.0
	var seed_value := variant

	_yard(p, rng, facing)

	# Fassaden
	var left_f: Array = []
	var right_f: Array = []
	var rows := [4] if style != "tall" else [3, 14]
	for ry in rows:
		left_f.append(_window(2, ry, 5, 7, rng))
		left_f.append(_window(int(cols) - 7, ry, 5, 7, rng))
		right_f.append(_window(2, ry, 5, 7, rng))
		right_f.append(_window(int(cols) - 7, ry, 5, 7, rng))
	var door := {"kind": "door", "x": int(cols) / 2 - 3, "y": 1, "w": 6, "h": 10, "color": door_col, "frame": Pal.BONE}
	match facing:
		"left":
			left_f.push_front(door)
			left_f = left_f.filter(func(f): return f.kind == "door" or f.y > 11 or absi(f.x - door.x) > 6)
		"right":
			right_f.push_front(door)
			right_f = right_f.filter(func(f): return f.kind == "door" or f.y > 11 or absi(f.x - door.x) > 6)
	p.wall_left(u0, u1, v1, 0, H, _facade(mat, wall, cols, H, left_f, false, seed_value, trim))
	p.wall_right(u1, v0, v1, 0, H, _facade(mat, wall, cols, H, right_f, true, seed_value + 1, Shade.dark(trim) if trim.a > 0.0 else trim))
	if style == "tall":
		# Gesims zwischen den Stockwerken
		p.line3(Vector3(u0, v1, 13), Vector3(u1, v1, 13), Shade.light(wall))
		p.line3(Vector3(u1, v1, 13), Vector3(u1, v0, 13), wall)
	# Lampe neben der Tür
	if facing == "left":
		var lp := p.P(u0 + (door.x + 7) / 32.0, v1, 9)
		p.c.px(int(lp.x), int(lp.y), Pal.YELLOW)
		p.g.px(int(lp.x), int(lp.y), Pal.WHITE)
		p.g.px(int(lp.x) - 1, int(lp.y), Pal.a(Pal.OCHRE, 0.45))
		p.g.px(int(lp.x) + 1, int(lp.y), Pal.a(Pal.OCHRE, 0.45))
		p.g.px(int(lp.x), int(lp.y) + 1, Pal.a(Pal.OCHRE, 0.45))
	elif facing == "right":
		var lp2 := p.P(u1, v1 - (door.x + 7) / 32.0, 9)
		p.c.px(int(lp2.x), int(lp2.y), Pal.YELLOW)
		p.g.px(int(lp2.x), int(lp2.y), Pal.WHITE)

	var gable_l := _facade(mat, wall, cols, 12.0, [], false, seed_value + 3, trim)
	var gable_r := _facade(mat, wall, cols, 12.0, [], true, seed_value + 4)
	match style:
		"gable_u":
			_gable(p, u0, v0, u1, v1, H, 11, 0.05, "u", roof, gable_l, gable_r)
			_chimney(p, u0 + 0.15, 0.36, H + 6, H + 15, meta)
		"gable_v":
			_gable(p, u0, v0, u1, v1, H, 11, 0.05, "v", roof, gable_l, gable_r)
			# Rundes Fenster im Giebel
			var gp := p.P((u0 + u1) * 0.5, v1, H + 4)
			p.c.disc(gp.x, gp.y, 2.2, Pal.BONE)
			p.c.disc(gp.x, gp.y, 1.3, Pal.BLUE_D)
			p.g.disc(gp.x, gp.y, 1.3, GLASS_GLOW)
			_chimney(p, 0.62, v0 + 0.12, H + 6, H + 15, meta)
		"tall":
			_flat_roof(p, u0, v0, u1, v1, H, Shade.light(wall), seed_value)
			p.box(u0 + 0.12, v0 + 0.1, u0 + 0.3, v0 + 0.25, H, H + 3, Pal.BLUE, Pal.BLUE_D, Pal.SKY)
			var ant := p.P(u1 - 0.15, v0 + 0.15, H)
			p.c.vline(int(ant.x), int(ant.y) - 9, 9, Pal.STONE_L)
			p.c.hline(int(ant.x) - 3, int(ant.y) - 8, 7, Pal.STONE_L)
			p.c.hline(int(ant.x) - 2, int(ant.y) - 6, 5, Pal.STONE_L)
			meta.blink.append(Vector2(int(ant.x), int(ant.y) - 10))
			_chimney(p, u0 + 0.35, v0 + 0.15, H, H + 6, meta)
	p.c.outline(Pal.NIGHT)
	_fence(p, rng, facing)
	return _result(p, meta, 1, 1)


## Vorgarten: Weg zur Tür, Rasenkante, ein Busch.
static func _yard(p: IsoPainter, rng: RandomNumberGenerator, facing: String) -> void:
	match facing:
		"left":
			p.ground(0.43, 0.8, 0.57, 1.0, 0, func(s, t, x, y): return Pal.STONE if (int(t * 6.0) % 2 == 0 and (x + y) % 5 == 0) else Pal.STONE_L)
		"right":
			p.ground(0.8, 0.43, 1.0, 0.57, 0, func(s, t, x, y): return Pal.STONE if (int(s * 6.0) % 2 == 0 and (x + y) % 5 == 0) else Pal.STONE_L)
	# Busch an der Ecke
	if rng.randf() < 0.75:
		var bp := p.P(0.86, 0.86, 0) if facing != "right" else p.P(0.86, 0.12, 0)
		if facing == "left":
			bp = p.P(0.86, 0.2, 0)
		p.c.disc(bp.x, bp.y - 2, 3.0, Pal.MOSS)
		p.c.disc(bp.x - 0.5, bp.y - 2.5, 1.9, Pal.GRASS)
		p.c.px(int(bp.x) - 1, int(bp.y) - 4, Pal.GRASS_L)
		if rng.randf() < 0.5:
			p.c.px(int(bp.x) + 1, int(bp.y) - 2, Pal.ROSE)
			p.c.px(int(bp.x) - 2, int(bp.y) - 1, Pal.ROSE)


## Lattenzaun an den beiden vorderen Kanten, mit Lücke am Weg.
static func _fence(p: IsoPainter, rng: RandomNumberGenerator, facing: String) -> void:
	if rng.randf() > 0.7:
		return
	var col: Color = _pick(rng, [Pal.BONE, Pal.WOOD_L, Pal.WOOD])
	var dk := Shade.dark(col)
	for i in 16:
		var f := (i + 0.5) / 16.0
		if facing == "left" and f > 0.4 and f < 0.6:
			continue
		var a := p.P(0.04 + f * 0.92, 0.96, 0)
		p.c.vline(int(a.x), int(a.y) - 4, 4, col if i % 2 == 0 else dk)
	for i in 16:
		var f2 := (i + 0.5) / 16.0
		if facing == "right" and f2 > 0.4 and f2 < 0.6:
			continue
		var b := p.P(0.96, 0.04 + f2 * 0.92, 0)
		p.c.vline(int(b.x), int(b.y) - 4, 4, dk if i % 2 == 0 else Shade.dark(dk))
	p.line3(Vector3(0.04, 0.96, 3), Vector3(0.96, 0.96, 3), col)
	p.line3(Vector3(0.96, 0.96, 3), Vector3(0.96, 0.04, 3), dk)


# Laden

static func shop(variant: int, material: String, facing: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = variant
	var p := IsoPainter.for_footprint(1, 1, 44)
	var meta := {"smoke": [], "blink": []}
	var wall: Color = Pal.BRICK if material == "ziegel" else Pal.STONE_L
	var awning: Color = _pick(rng, [Pal.ROSE, Pal.TEAL, Pal.OCHRE, Pal.BRICK, Pal.MOSS, Pal.BLUE])
	var kind := shop_kind(variant)
	var u0 := 0.14
	var u1 := 0.86
	var v0 := 0.14
	var v1 := 0.86
	var H := 22.0
	var cols := (u1 - u0) * 32.0
	var icon := _sign_icon(kind)
	var front: Array = [
		{"kind": "shop", "x": 2, "y": 2, "w": 12, "h": 10},
		{"kind": "glassdoor", "x": 16, "y": 1, "w": 5, "h": 11},
		{"kind": "sign", "x": 2, "y": 16, "w": int(cols) - 4, "h": 5, "color": Pal.NIGHT, "icon": icon},
	]
	var side: Array = [_window(3, 6, 5, 7, rng, Pal.STONE_L), _window(int(cols) - 9, 6, 5, 7, rng, Pal.STONE_L)]
	var left_f := front if facing != "right" else side
	var right_f := front if facing == "right" else side
	p.ground(0.0, 0.0, 1.0, 1.0, 0, func(s, t, x, y):
		# Pflaster vor dem Laden
		var edge: bool = (t > 0.88 and facing != "right") or (s > 0.88 and facing == "right")
		if not edge:
			return CLEAR
		return Pal.STONE_L if (x + y * 2) % 7 != 0 else Pal.STONE)
	p.wall_left(u0, u1, v1, 0, H, _facade(material, wall, cols, H, left_f, false, variant))
	p.wall_right(u1, v0, v1, 0, H, _facade(material, wall, cols, H, right_f, true, variant + 1))
	_flat_roof(p, u0 - 0.02, v0 - 0.02, u1 + 0.02, v1 + 0.02, H + 2, Shade.light(wall), variant)
	# Klimagerät auf dem Dach
	p.box(u0 + 0.1, v0 + 0.12, u0 + 0.32, v0 + 0.3, H + 2, H + 7, Pal.STONE_L, Pal.STONE, Pal.WHITE)
	var fan := p.P(u0 + 0.21, v0 + 0.21, H + 7)
	p.c.ellipse(fan.x, fan.y, 2.4, 1.2, Pal.STONE)
	# Markise über dem Schaufenster
	if facing != "right":
		p.quad(Vector3(u0, v1, 15), Vector3(u1 - u0, 0, 0), Vector3(0, 0.14, -4), func(s, t, _x, _y):
			var stripe := int(s * cols / 2.0) % 2 == 0
			var col: Color = awning if stripe else Pal.BONE
			if t > 0.8:
				return Shade.dark(col)
			return Shade.light(col) if t < 0.2 else col)
	else:
		p.quad(Vector3(u1, v1, 15), Vector3(0, v0 - v1, 0), Vector3(0.14, 0, -4), func(s, t, _x, _y):
			var stripe2 := int(s * cols / 2.0) % 2 == 0
			var col2: Color = awning if stripe2 else Pal.BONE
			return Shade.dark(col2) if t > 0.8 else col2)
	p.c.outline(Pal.NIGHT)
	# Obstkisten vor dem Laden
	var cp := p.P(0.2, 0.95, 0) if facing != "right" else p.P(0.95, 0.75, 0)
	p.c.rect(int(cp.x), int(cp.y) - 4, 6, 4, Pal.WOOD)
	p.c.hline(int(cp.x), int(cp.y) - 4, 6, Pal.WOOD_L)
	for k in 6:
		p.c.px(int(cp.x) + k, int(cp.y) - 5, _pick(rng, [Pal.BRICK_L, Pal.GRASS_L, Pal.OCHRE, Pal.YELLOW]))
	return _result(p, meta, 1, 1)


## Was der Laden verkauft. Hängt nur an der Variante, damit Bild und Name zusammenpassen.
static func shop_kind(variant: int) -> String:
	return ["can", "bread", "bottle"][absi(hash([variant, "kind"])) % 3]


static func _sign_icon(kind: String) -> Array:
	var out := []
	match kind:
		"can":
			for k in 3:
				for yy in range(1, 4):
					out.append({"x": 3 + k * 5, "y": yy, "c": Pal.BRICK_L})
					out.append({"x": 4 + k * 5, "y": yy, "c": Pal.BONE if yy == 2 else Pal.BRICK_L})
		"bread":
			for k in 3:
				for xx in range(0, 4):
					out.append({"x": 2 + k * 6 + xx, "y": 2, "c": Pal.OCHRE})
					out.append({"x": 2 + k * 6 + xx, "y": 1, "c": Pal.RUST})
				out.append({"x": 3 + k * 6, "y": 3, "c": Pal.YELLOW})
		_:
			for k in 4:
				out.append({"x": 3 + k * 4, "y": 3, "c": Pal.SKY})
				out.append({"x": 3 + k * 4, "y": 2, "c": Pal.TEAL})
				out.append({"x": 3 + k * 4, "y": 1, "c": Pal.TEAL})
				out.append({"x": 4 + k * 4, "y": 1, "c": Pal.WATER})
				out.append({"x": 4 + k * 4, "y": 2, "c": Pal.TEAL})
	return out


# Fabrik

static func factory(variant: int, material: String, facing: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = variant
	var p := IsoPainter.for_footprint(2, 2, 92)
	var meta := {"smoke": [], "blink": []}
	var wall: Color = Pal.BRICK if material == "ziegel" else Pal.STONE
	var mat := "ziegel" if material == "ziegel" else "stahl"
	var u0 := 0.15
	var u1 := 1.85
	var v0 := 0.62
	var v1 := 1.85
	var H := 26.0
	var colsL := (u1 - u0) * 32.0
	var colsR := (v1 - v0) * 32.0

	# Hof: Beton mit Warnstreifen
	p.ground(0.0, 0.0, 2.0, 2.0, 0, func(s, t, x, y):
		if t * 2.0 < 0.6 and s * 2.0 < 1.0:
			return CLEAR
		var n := _noise(x, y, variant)
		var col := Pal.STONE_L if n > 120 else Pal.STONE
		if t * 2.0 > 1.86 and s * 2.0 > 0.75 and s * 2.0 < 1.35:
			col = Pal.YELLOW if (x / 2 + y) % 4 < 2 else Pal.NIGHT
		return col)
	# Silo hinten links
	p.cylinder(0.42, 0.36, 0.22, 0, 52, [Pal.WHITE, Pal.STONE_L, Pal.STONE_L, Pal.STONE, Pal.STONE_D], Pal.STONE)
	for k in 4:
		var rp := p.P(0.42, 0.36, 10 + k * 11)
		p.c.hline(int(rp.x) - 9, int(rp.y), 19, Pal.STONE)
	# Schornstein hinten rechts
	p.cylinder(1.45, 0.3, 0.1, 0, 84, [Pal.BRICK_L, Pal.BRICK, Pal.BRICK, Pal.BRICK_D], Pal.STONE_D, true)
	for band in [30, 31, 58, 59]:
		var bp := p.P(1.45, 0.3, band)
		p.c.hline(int(bp.x) - 4, int(bp.y), 9, Pal.BONE if band % 2 == 0 else Pal.STONE_L)
	var top := p.P(1.45, 0.3, 84)
	meta.smoke.append(top + Vector2(0, -2))
	meta.blink.append(top + Vector2(4, 1))
	# Rohr vom Silo zur Halle
	p.line3(Vector3(0.55, 0.45, 34), Vector3(0.7, 0.62, 34), Pal.RUST)
	p.line3(Vector3(0.55, 0.45, 33), Vector3(0.7, 0.62, 33), Pal.SOIL)

	# Halle
	var front: Array = []
	var side: Array = []
	for i in 4:
		front.append({"kind": "window", "x": 4 + i * 8 + (16 if i >= 2 else 0), "y": 12, "w": 6, "h": 9, "frame": Pal.STONE_D, "curtain": Color(0, 0, 0, 0)})
	front.append({"kind": "roller", "x": int(colsL / 2) - 8, "y": 1, "w": 16, "h": 18})
	front.append({"kind": "band", "x": int(colsL / 2) - 8, "y": 19, "w": 16, "h": 1, "color": Pal.YELLOW})
	for i in 3:
		side.append({"kind": "window", "x": 4 + i * 12, "y": 10, "w": 6, "h": 9, "frame": Pal.STONE_D, "curtain": Color(0, 0, 0, 0)})
	side.append({"kind": "door", "x": int(colsR) - 9, "y": 1, "w": 5, "h": 9, "color": Pal.TEAL_D, "frame": Pal.STONE_D})
	p.wall_left(u0, u1, v1, 0, H, _facade(mat, wall, colsL, H, front if facing != "right" else side, false, variant))
	p.wall_right(u1, v0, v1, 0, H, _facade(mat, wall, colsR, H, side if facing != "right" else front, true, variant + 1))
	# Sheddach: Zähne laufen nach rechts unten, Glas zeigt nach vorne links
	var teeth := 4
	var dv := (v1 - v0) / teeth
	for k in teeth:
		var vk := v0 + k * dv
		# Blechfläche steigt nach vorne an
		p.quad(Vector3(u0, vk, H), Vector3(u1 - u0, 0, 0), Vector3(0, dv, 9), func(s, t, x, y):
			var ax := int(s * colsL)
			if ax % 3 == 0:
				return Pal.STONE_D
			if _noise(ax, k, variant) < 40 and t > 0.4:
				return Pal.RUST
			return Pal.STONE if t < 0.5 else Pal.STONE_L)
		# Glasband vorne, senkrecht
		p.wall_left(u0, u1, vk + dv, H, H + 9, func(s, t, x, y):
			var ax2 := int(s * colsL)
			if ax2 % 7 == 0 or t < 0.12:
				return Pal.SLATE
			if t > 0.85:
				return [Pal.BLUE, Pal.a(Pal.YELLOW, 0.6)]
			return [Pal.BLUE_D, Pal.a(Pal.YELLOW, 0.6)])
		# Seitendreieck rechts
		p.quad(Vector3(u1, vk + dv, H), Vector3(0, -dv, 0), Vector3(0, 0, 9), func(s, t, _x, _y): return Shade.dark(wall) if s + t <= 1.0 else CLEAR)
	p.c.outline(Pal.NIGHT)
	# Fässer und Paletten im Hof
	for k in 3:
		var fp := p.P(0.25 + k * 0.12, 1.95, 0)
		var col: Color = _pick(rng, [Pal.RUST, Pal.TEAL, Pal.BLUE, Pal.BRICK])
		p.c.rect(int(fp.x) - 2, int(fp.y) - 6, 4, 6, col)
		p.c.vline(int(fp.x) - 2, int(fp.y) - 6, 6, Shade.light(col))
		p.c.hline(int(fp.x) - 2, int(fp.y) - 6, 4, Shade.light(Shade.light(col)))
		p.c.hline(int(fp.x) - 2, int(fp.y) - 3, 4, Shade.dark(col))
	var pp := p.P(1.95, 1.4, 0)
	p.c.rect(int(pp.x) - 4, int(pp.y) - 5, 8, 4, Pal.WOOD_L)
	p.c.frame(int(pp.x) - 4, int(pp.y) - 5, 8, 4, Pal.WOOD)
	p.c.hline(int(pp.x) - 4, int(pp.y) - 1, 8, Pal.SOIL)
	return _result(p, meta, 2, 2)


# Kraftwerk

static func power_plant(variant: int, _material: String, _facing: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = variant
	var p := IsoPainter.for_footprint(2, 2, 98)
	var meta := {"smoke": [], "blink": []}
	# Kies im Umspannwerk vorne links
	p.ground(0.08, 1.15, 0.95, 1.92, 0, func(s, t, x, y):
		var n := _noise(x, y, variant)
		return Pal.STONE if n < 300 else (Pal.STONE_D if n < 700 else Pal.SLATE))
	# Kühlturm hinten links: Hyperboloid, Zeile für Zeile
	var cu := 0.62
	var cv := 0.6
	var cen := p.P(cu, cv, 0)
	var Ht := 78.0
	for zi in int(Ht):
		var tt := float(zi) / Ht
		var r := 0.0
		if tt < 0.72:
			var uu := (tt - 0.72) / 0.72
			r = 0.33 + 0.16 * uu * uu
		else:
			r = 0.33 + (tt - 0.72) / 0.28 * 0.05
		var rx := r * 45.25
		var ry := r * 22.63
		var yrow := cen.y - zi
		for x in range(floori(cen.x - rx), ceili(cen.x + rx) + 1):
			var nx := (x + 0.5 - cen.x) / rx
			if absf(nx) > 1.0:
				continue
			var sh := (nx + 1.0) * 0.5
			var col := Pal.STONE
			if sh < 0.1:
				col = Pal.STONE_L
			elif sh < 0.36:
				col = Pal.BONE
			elif sh < 0.6:
				col = Pal.STONE_L
			elif sh < 0.88:
				col = Pal.STONE
			else:
				col = Pal.STONE_D
			if zi % 11 == 0:
				col = Shade.dark(col)
			# Unterkante als Ellipse
			var dy := 0
			if zi == 0:
				dy = int(sqrt(maxf(0.0, 1.0 - nx * nx)) * ry)
				for yy in range(int(yrow), int(yrow) + dy + 1):
					p.c.px(x, yy, Pal.STONE_D if yy > yrow + dy - 2 else col)
			p.c.px(x, int(yrow), col)
	# Öffnung oben
	var topc := cen - Vector2(0, Ht)
	var rt := 0.38
	p.c.ellipse(topc.x, topc.y, rt * 45.25, rt * 22.63, Pal.STONE_L)
	p.c.ellipse(topc.x, topc.y + 0.5, rt * 45.25 - 2, rt * 22.63 - 1.5, Pal.NIGHT)
	meta.smoke.append(topc)
	meta.blink.append(topc + Vector2(rt * 45.25 - 1, 0))
	# Turbinenhalle rechts vorne
	var u0 := 1.0
	var u1 := 1.92
	var v0 := 0.55
	var v1 := 1.92
	var H := 24.0
	var colsL := (u1 - u0) * 32.0
	var colsR := (v1 - v0) * 32.0
	var front: Array = [
		{"kind": "band", "x": 0, "y": 16, "w": int(colsL), "h": 2, "color": Pal.TEAL},
		{"kind": "window", "x": 3, "y": 9, "w": int(colsL) - 6, "h": 5, "frame": Pal.STONE_D, "curtain": Color(0, 0, 0, 0)},
		{"kind": "roller", "x": int(colsL) - 11, "y": 1, "w": 8, "h": 7},
	]
	var side: Array = [
		{"kind": "band", "x": 0, "y": 16, "w": int(colsR), "h": 2, "color": Pal.TEAL},
		{"kind": "window", "x": 4, "y": 9, "w": int(colsR) - 8, "h": 5, "frame": Pal.STONE_D, "curtain": Color(0, 0, 0, 0)},
	]
	p.wall_left(u0, u1, v1, 0, H, _facade("beton", Pal.STONE_L, colsL, H, front, false, variant))
	p.wall_right(u1, v0, v1, 0, H, _facade("beton", Pal.STONE_L, colsR, H, side, true, variant + 1))
	_flat_roof(p, u0 - 0.02, v0 - 0.02, u1 + 0.02, v1 + 0.02, H + 2, Pal.STONE_L, variant)
	for k in 3:
		p.box(u0 + 0.2, v0 + 0.2 + k * 0.4, u0 + 0.55, v0 + 0.4 + k * 0.4, H + 2, H + 4, Pal.BLUE, Pal.BLUE_D, Pal.SKY)
	# Trafos
	for k in 2:
		var tu := 0.25 + k * 0.38
		p.box(tu, 1.4, tu + 0.25, 1.65, 0, 10, Pal.STONE, Pal.STONE_D, Pal.STONE_L)
		for ii in 3:
			var ip := p.P(tu + 0.05 + ii * 0.08, 1.45, 10)
			p.c.vline(int(ip.x), int(ip.y) - 3, 3, Pal.BONE)
	p.c.outline(Pal.NIGHT)
	# Zaun ums Umspannwerk
	for i in 20:
		var f := (i + 0.5) / 20.0
		var a := p.P(0.08 + f * 0.87, 1.92, 0)
		p.c.vline(int(a.x), int(a.y) - 5, 5, Pal.STONE_L if i % 2 == 0 else Pal.STONE)
	p.line3(Vector3(0.08, 1.92, 5), Vector3(0.95, 1.92, 5), Pal.STONE_L)
	# Warnschild
	var wp := p.P(0.5, 1.92, 3)
	p.c.poly(PackedVector2Array([Vector2(wp.x - 3, wp.y), Vector2(wp.x, wp.y - 5), Vector2(wp.x + 3, wp.y)]), Pal.YELLOW)
	p.c.px(int(wp.x), int(wp.y) - 2, Pal.BLACK)
	return _result(p, meta, 2, 2)


# Wasserturm: gemauerter Turm mit Bogenfenstern, darauf ein genieteter Behälter unter Kupferdach

static func water_tower(variant: int, _material: String, _facing: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = variant
	var p := IsoPainter.for_footprint(1, 1, 112)
	var meta := {"smoke": [], "blink": []}
	var shaft: Color = _pick(rng, [Pal.BRICK, Pal.BRICK, Pal.BRICK_L, Pal.SAND])
	var tank_col: Color = _pick(rng, [Pal.TEAL, Pal.WATER, Pal.STONE_L, Pal.MOSS])
	var roof_col: Color = _pick(rng, [Pal.TEAL_D, Pal.MOSS, Pal.SLATE, Pal.BRICK_D])
	var cu := 0.5
	var cv := 0.5
	var Z_PLINTH := 6.0
	var Z_SHAFT := 52.0
	var Z_GALLERY := 57.0
	var Z_TANK := 80.0
	var Z_ROOF := 98.0

	# Steinplatte rund um den Turm
	p.ground(0.08, 0.08, 0.92, 0.92, 0, func(s, t, x, y):
		if s < 0.05 or t < 0.05 or s > 0.95 or t > 0.95:
			return Pal.STONE_D
		var n := _noise(x, y, variant)
		if (int(s * 12.0) + int(t * 12.0)) % 2 == 0:
			return Pal.STONE_L if n > 100 else Pal.STONE
		return Pal.STONE if n > 60 else Pal.STONE_D)

	# Sockel aus Quadern
	p.cyl_fill(cu, cv, 0.38, 0, Z_PLINTH, func(sh, z, x, y, _nx):
		var col := Pal.STONE_L
		if int(z) % 3 == 0:
			col = Pal.STONE
		if sh < 0.18:
			col = Shade.light(col)
		elif sh > 0.74:
			col = Shade.dark(col)
		return col)
	p.cap(cu, cv, 0.38, Z_PLINTH, Pal.STONE_L)

	# Schaft: Ziegel im Verband, Bogenfenster in drei Stockwerken, Tür unten
	var wins: Array = []
	var floors := [[21.0, [-0.62, 0.0, 0.62]], [31.0, [-0.31, 0.31]], [41.0, [-0.62, 0.0, 0.62]]]
	for f in floors:
		for th in f[1]:
			wins.append({"th": th, "z0": f[0], "h": 8.0, "hw": 0.17, "door": false})
	wins.append({"th": 0.0, "z0": Z_PLINTH, "h": 13.0, "hw": 0.2, "door": true})
	p.cyl_fill(cu, cv, 0.34, Z_PLINTH, Z_SHAFT, func(sh, z, x, y, nx):
		var th := asin(clampf(nx, -1.0, 1.0))
		var zz := int(z) - int(Z_PLINTH)
		for w in wins:
			var dz: float = z - w.z0
			if dz < 0.0 or dz >= w.h:
				continue
			var top_off: float = w.h - 1.0 - dz
			var hw: float = w.hw
			if top_off < 3.0:
				hw *= [0.5, 0.78, 0.92][int(top_off)]
			var d := absf(th - float(w.th))
			if d > hw:
				continue
			var shade_dark: bool = sh > 0.74
			var frame := Pal.BONE if not shade_dark else Pal.STONE_L
			if d > hw - 0.05 or dz < 1.0 or top_off < 1.0:
				return frame
			if w.door:
				var door_col := Pal.WOOD if not shade_dark else Pal.SOIL
				if int(z) == int(Z_PLINTH) + 7 and d < 0.04:
					return Pal.YELLOW
				return door_col if fposmod(th, 0.14) > 0.04 else Shade.dark(door_col)
			return [Pal.BLUE_D if dz < 6.0 else Pal.BLUE, GLASS_GLOW]
		var course := zz / 3
		var u := (th + PI * 0.5) * 11.0 + (course % 2) * 0.5
		var col := shaft
		if zz % 3 == 2 or fposmod(u, 1.0) < 0.13:
			col = Shade.dark(shaft)
		else:
			var n := _noise(int(floor(u)), course, variant)
			if n < 120:
				col = Shade.light(shaft)
			elif n < 200:
				col = Shade.dark(shaft)
		if sh < 0.16:
			col = Shade.light(col)
		elif sh > 0.78:
			col = Shade.dark(col)
		if sh > 0.9:
			col = Shade.dark(col)
		return col)

	# Gesims und Umgang mit Geländer
	p.cyl_fill(cu, cv, 0.4, Z_SHAFT, Z_GALLERY, func(sh, z, _x, _y, _nx):
		var col := Pal.STONE_L if z > Z_SHAFT + 2.0 else Pal.STONE
		if int(z) == int(Z_SHAFT):
			col = Pal.STONE_D
		if sh < 0.18:
			col = Shade.light(col)
		elif sh > 0.74:
			col = Shade.dark(col)
		return col)
	p.cap(cu, cv, 0.4, Z_GALLERY, Pal.STONE, Pal.STONE_L)
	var ring := p.P(cu, cv, Z_GALLERY)
	for i in 40:
		var ang := TAU * i / 40.0
		if sin(ang) < -0.2:
			continue
		var rp := ring + Vector2(cos(ang) * 0.385 * 45.25, sin(ang) * 0.385 * 22.63)
		p.c.px(int(rp.x), int(rp.y) - 3, Pal.STONE_D)
		if i % 4 == 0:
			p.c.vline(int(rp.x), int(rp.y) - 3, 3, Pal.STONE_D)

	# Behälter: Blechplatten, Nietenreihen, Tropfen vorn
	p.cyl_fill(cu, cv, 0.35, Z_GALLERY, Z_TANK, func(sh, z, x, y, nx):
		var th := asin(clampf(nx, -1.0, 1.0))
		var zz := int(z) - int(Z_GALLERY)
		var col := tank_col
		if fposmod((th + PI * 0.5) * 6.0, 1.0) < 0.1:
			col = Shade.dark(col)
		if zz % 7 == 0:
			col = Shade.dark(col)
		elif zz % 7 == 1 and x % 3 == 0:
			col = Shade.light(col)
		if sh < 0.16:
			col = Shade.light(col)
		elif sh > 0.78:
			col = Shade.dark(col)
		elif sh > 0.9:
			col = Shade.dark(col)
		return col)
	p.cap(cu, cv, 0.35, Z_TANK, Shade.dark(tank_col))
	var cen := p.P(cu, cv, 0)
	var dp := Vector2(cen.x, cen.y + 0.35 * 22.63 - (Z_GALLERY + 14.0))
	p.c.px(int(dp.x), int(dp.y) - 3, Pal.WHITE)
	p.c.hline(int(dp.x) - 1, int(dp.y) - 2, 3, Pal.WHITE)
	p.c.rect(int(dp.x) - 2, int(dp.y) - 1, 5, 3, Pal.WHITE)
	p.c.hline(int(dp.x) - 1, int(dp.y) + 2, 3, Pal.WHITE)
	p.c.px(int(dp.x) - 1, int(dp.y), Pal.SKY)

	# Dach: Kupfer mit Schindelreihen
	p.cone_fill(cu, cv, 0.41, Z_TANK, Z_ROOF, func(sh, t, x, y, _nx):
		var row := int(t * 20.0)
		var col := roof_col
		if row % 3 == 0:
			col = Shade.dark(col)
		elif (x + row * 2) % 5 == 0:
			col = Shade.dark(col)
		if t < 0.06:
			col = Shade.dark(Shade.dark(col))
		if sh < 0.3:
			col = Shade.light(col)
		elif sh > 0.66:
			col = Shade.dark(col)
		if t > 0.88:
			col = Shade.light(col)
		return col)

	# Laterne und Spitze
	p.cyl_fill(cu, cv, 0.06, Z_ROOF, Z_ROOF + 6.0, func(sh, z, _x, _y, _nx):
		return [Pal.BONE if sh < 0.5 else Pal.STONE_L, Color(0, 0, 0, 0)] if z > Z_ROOF + 1.0 else Pal.STONE_D)
	var tip := p.P(cu, cv, Z_ROOF + 6.0)
	p.c.vline(int(tip.x), int(tip.y) - 5, 5, Pal.STONE_D)
	p.c.px(int(tip.x), int(tip.y) - 6, Pal.BRICK_L)
	meta.blink.append(Vector2(int(tip.x), int(tip.y) - 6))
	p.c.outline(Pal.NIGHT)

	# Büsche am Fuß
	for bp in [Vector2(0.14, 0.72), Vector2(0.84, 0.22), Vector2(0.78, 0.84)]:
		var q := p.P(bp.x, bp.y, 0)
		p.c.disc(q.x, q.y - 2, 3.0, Pal.MOSS)
		p.c.disc(q.x - 0.5, q.y - 2.5, 1.9, Pal.GRASS)
		p.c.px(int(q.x) - 1, int(q.y) - 4, Pal.GRASS_L)
		if rng.randf() < 0.5:
			p.c.px(int(q.x) + 1, int(q.y) - 2, Pal.ROSE)
	return _result(p, meta, 1, 1)


# Park

static func park(variant: int, _material: String, _facing: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = variant
	var p := IsoPainter.for_footprint(1, 1, 40)
	var meta := {"smoke": [], "blink": [], "lamp": []}
	var kind: int = rng.randi() % 3
	# Rasen mit Mähstreifen und Heckenrand
	p.ground(0.02, 0.02, 0.98, 0.98, 0, func(s, t, x, y):
		if s < 0.06 or t < 0.06 or s > 0.94 or t > 0.94:
			return Pal.MOSS if (x + y) % 3 else Pal.MOSS_D
		var stripe := int(s * 8.0) % 2 == 0
		var col := Pal.GRASS_L if stripe else Pal.GRASS
		if PixelCanvas.bayer(x, y, 0.12):
			col = Shade.light(col)
		return col)
	match kind:
		0:
			# Geschwungener Weg, Baum, Bank, Beet
			p.ground(0.06, 0.06, 0.94, 0.94, 0, func(s, t, x, y):
				var curve := 0.5 + sin(s * PI * 1.6) * 0.18
				if absf(t - curve) < 0.08:
					return Pal.SAND if (x + y) % 6 else Pal.WOOD_L
				return CLEAR)
			_bed(p, rng, 0.6, 0.72, 0.88, 0.9)
			_bench(p, 0.25, 0.75)
			_tree(p, rng, 0.32, 0.3, 10.0)
			_lamp(p, 0.8, 0.3, meta)
		1:
			# Brunnen mit Wegkreuz
			p.ground(0.06, 0.43, 0.94, 0.57, 0, func(_s, _t, x, y): return Pal.SAND if (x + y) % 7 else Pal.WOOD_L)
			p.ground(0.43, 0.06, 0.57, 0.94, 0, func(_s, _t, x, y): return Pal.SAND if (x + y) % 7 else Pal.WOOD_L)
			var fc := p.P(0.5, 0.5, 0)
			p.c.ellipse(fc.x, fc.y, 13, 6.5, Pal.STONE_L)
			p.c.ellipse(fc.x, fc.y - 1, 12, 5.5, Pal.STONE)
			p.c.ellipse(fc.x, fc.y, 10.5, 4.6, Pal.WATER)
			p.c.ellipse(fc.x - 2, fc.y - 1, 6, 2, Pal.SKY)
			p.c.ellipse(fc.x + 1, fc.y + 1, 7, 2.6, Pal.TEAL)
			p.c.rect(int(fc.x) - 1, int(fc.y) - 7, 2, 7, Pal.STONE_L)
			p.c.px(int(fc.x) - 1, int(fc.y) - 8, Pal.WHITE)
			meta["fountain"] = Vector2(fc.x, fc.y - 8)
			for bp in [Vector2(0.2, 0.2), Vector2(0.8, 0.2), Vector2(0.2, 0.8), Vector2(0.8, 0.8)]:
				var q := p.P(bp.x, bp.y, 0)
				p.c.disc(q.x, q.y - 2, 3, Pal.MOSS)
				p.c.disc(q.x - 0.5, q.y - 2.5, 2, Pal.GRASS)
				p.c.px(int(q.x) - 1, int(q.y) - 4, Pal.GRASS_L)
			_lamp(p, 0.62, 0.3, meta)
		_:
			# Spielplatz
			p.ground(0.15, 0.55, 0.5, 0.88, 0, func(s, t, x, y):
				if s < 0.08 or t < 0.08 or s > 0.92 or t > 0.92:
					return Pal.WOOD
				return Pal.SAND if _noise(x, y, 3) > 80 else Pal.OCHRE)
			# Schaukel
			for sp in [Vector2(0.62, 0.3), Vector2(0.62, 0.7)]:
				p.line3(Vector3(sp.x - 0.06, sp.y, 0), Vector3(sp.x, sp.y, 16), Pal.WOOD)
				p.line3(Vector3(sp.x + 0.06, sp.y, 0), Vector3(sp.x, sp.y, 16), Pal.WOOD_L)
			p.line3(Vector3(0.62, 0.3, 16), Vector3(0.62, 0.7, 16), Pal.WOOD_L)
			for sv in [0.42, 0.56]:
				var top := p.P(0.62, sv, 16)
				var bot := p.P(0.62, sv, 5)
				p.c.vline(int(top.x), int(top.y), int(bot.y - top.y), Pal.STONE_L)
				p.c.rect(int(bot.x) - 1, int(bot.y), 3, 1, Pal.BRICK)
			_tree(p, rng, 0.25, 0.25, 7.0)
	p.c.outline(Pal.MOSS_D)
	return _result(p, meta, 1, 1)


static func _bed(p: IsoPainter, rng: RandomNumberGenerator, u0: float, v0: float, u1: float, v1: float) -> void:
	p.ground(u0, v0, u1, v1, 0, func(_s, _t, x, y):
		if (x + y) % 2 == 0:
			return Pal.GRASS
		var n := _noise(x, y, 17)
		if n < 350:
			return [Pal.ROSE, Pal.YELLOW, Pal.WHITE, Pal.BRICK_L, Pal.BLUE][n % 5]
		return Pal.SOIL)
	rng = rng


static func _bench(p: IsoPainter, u: float, v: float) -> void:
	p.box(u, v, u + 0.24, v + 0.07, 3, 4, Pal.WOOD_L, Pal.WOOD, Pal.WOOD_L)
	p.box(u, v - 0.02, u + 0.24, v, 4, 8, Pal.WOOD, Pal.SOIL, Pal.WOOD_L)
	for k in [0.02, 0.2]:
		var a := p.P(u + k, v + 0.07, 0)
		p.c.vline(int(a.x), int(a.y) - 3, 3, Pal.STONE_D)


static func _tree(p: IsoPainter, rng: RandomNumberGenerator, u: float, v: float, r: float) -> void:
	var base := p.P(u, v, 0)
	p.c.rect(int(base.x) - 1, int(base.y - r - 6), 3, int(r) + 6, Pal.WOOD)
	p.c.vline(int(base.x) + 1, int(base.y - r - 6), int(r) + 6, Pal.SOIL)
	NatureArt.crown(p.c, rng, Vector2(base.x + 0.5, base.y - r - 6 - r * 0.45), r, r * 0.85)


static func _lamp(p: IsoPainter, u: float, v: float, meta: Dictionary) -> void:
	var b := p.P(u, v, 0)
	var x := int(b.x)
	var y := int(b.y)
	p.c.vline(x, y - 13, 13, Pal.STONE_D)
	p.c.hline(x - 1, y, 3, Pal.SLATE)
	p.c.rect(x - 1, y - 15, 3, 2, Pal.YELLOW)
	p.c.hline(x - 1, y - 16, 3, Pal.STONE_D)
	p.g.rect(x - 1, y - 15, 3, 2, Pal.WHITE)
	p.g.disc(x, y - 14, 3, Pal.a(Pal.YELLOW, 0.35))
	meta.lamp.append(Vector2(x, y))


## Kleine Ziffern 3x5.
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


static func make(type: String, variant: int, material: String, facing: String = "left") -> Dictionary:
	match type:
		"house": return house(variant, material, facing)
		"shop": return shop(variant, material, facing)
		"factory": return factory(variant, material, facing)
		"power_plant": return power_plant(variant, material, facing)
		"water_tower": return water_tower(variant, material, facing)
		"park": return park(variant, material, facing)
	return house(variant, material, facing)
