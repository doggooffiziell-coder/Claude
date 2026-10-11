class_name World
extends Node2D
## Boden-Grid als TileMapLayer, Tunnel, Wegfelder, Wasser, Sandhügel und Futterquellen.

const T := 3            # Pixel pro Zelle
const W := 86           # Zellen in der Breite
const H := 156          # Zellen in der Höhe
const G := 40           # erste Erdreihe
const SURF := 39        # Reihe, auf der Ameisen oberirdisch laufen
const ENT := 43         # Spalte des Nesteingangs
const FRAME := 6        # Breite des grünen Rahmens in Pixeln
const LAYER_ROWS := [40, 79, 118]
const INF := 1 << 28
const ARRIVED := Vector2i(-1, -1)
const NO_PATH := Vector2i(-2, -2)

enum { AIR, SOIL, TUNNEL }
enum { CH_NONE, CH_GRANARY, CH_BROOD, CH_QUEEN, CH_CEMETERY, CH_TRASH }
enum { F_EXIT, F_GRANARY, F_BROOD, F_QUEEN, F_CEMETERY, F_TRASH, F_DIG, F_CORPSE, F_COUNT }

const SOIL_COLORS := [Color(0.87, 0.76, 0.53), Color(0.82, 0.70, 0.48), Color(0.73, 0.62, 0.43)]
const TUNNEL_COLOR := Color(0.36, 0.24, 0.14)
const RIM_COLOR := Color(0.52, 0.38, 0.23)
const CHAMBER_COLORS := [
	Color(0, 0, 0),
	Color(0.72, 0.62, 0.24),   # Kornkammer gelb
	Color(0.52, 0.38, 0.55),   # Brutkammer lila
	Color(0.30, 0.28, 0.30),   # Königinnenkammer dunkelgrau
	Color(0.45, 0.51, 0.40),   # Friedhof grau-grün
	Color(0.68, 0.56, 0.40),   # Müllkammer hellbraun
]

var main
var cells := PackedByteArray()
var chamber := PackedByteArray()
var chamber_cells: Array = []      # pro Kammertyp die gegrabenen Zellindizes
var fields: Array = []
var field_dirty: Array = []
var field_has: Array = []
var water := PackedFloat32Array()
var wet := false
var mound := PackedFloat32Array()
var sources: Array = []            # Bäume und Büsche mit Früchten
var source_by_trunk := {}
var seed_value := 0

var _water_frame := 0
var _water_img: Image
var _water_tex: ImageTexture
var _water_shown := false

@onready var ground: TileMapLayer = $Ground
@onready var sky: Node2D = $Sky
@onready var decor: Node2D = $Decor
@onready var water_sprite: Sprite2D = $Water
@onready var frame_node: Node2D = $Frame


func setup(m) -> void:
	main = m
	sky.world = self
	sky.main = m
	decor.main = m
	ground.tile_set = _build_tileset()
	_water_img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	_water_tex = ImageTexture.create_from_image(_water_img)
	water_sprite.texture = _water_tex
	water_sprite.centered = false
	water_sprite.scale = Vector2(T, T)
	frame_node.draw.connect(_draw_frame)
	frame_node.queue_redraw()


# ---------------------------------------------------------------- Welt anlegen

func new_world(s: int) -> void:
	seed_value = s
	cells.resize(W * H)
	chamber.resize(W * H)
	water.resize(W * H)
	water.fill(0.0)
	mound.resize(W)
	mound.fill(0.0)
	for y in H:
		for x in W:
			cells[y * W + x] = AIR if y < G else SOIL
	chamber.fill(0)
	_generate_sources()
	_reset_runtime()
	rebuild_tiles()


func _reset_runtime() -> void:
	chamber_cells.clear()
	for t in 6:
		chamber_cells.append(PackedInt32Array())
	for i in W * H:
		if cells[i] == TUNNEL and chamber[i] != 0:
			chamber_cells[chamber[i]].append(i)
	fields.clear()
	field_dirty.clear()
	field_has.clear()
	for f in F_COUNT:
		var arr := PackedInt32Array()
		arr.resize(W * H)
		arr.fill(INF)
		fields.append(arr)
		field_dirty.append(true)
		field_has.append(false)
	wet = false
	water.fill(0.0)
	_water_shown = true


func _generate_sources() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	sources.clear()
	source_by_trunk.clear()
	# Laubbäume: Stamm-Spalte, Kronenmitte und Radius in Zellen
	var tree_x := [7, 22, 63, 78]
	for tx in tree_x:
		var cy := r.randi_range(13, 18)
		var rad := r.randi_range(7, 9)
		var src := {"kind": 0, "trunk": tx, "cx": tx + r.randi_range(-1, 1), "cy": cy, "r": rad, "fruits": [], "blobs": []}
		for b in 9:
			var a := r.randf() * TAU
			var d := r.randf() * rad * 0.7
			src.blobs.append([cos(a) * d, sin(a) * d * 0.75, r.randf_range(rad * 0.45, rad * 0.7), r.randi_range(0, 2)])
		for f in 7:
			var fx := clampi(tx + r.randi_range(-rad + 2, rad - 2), 1, W - 2)
			var fy := clampi(cy + r.randi_range(-rad + 3, rad - 2), 4, SURF - 6)
			src.fruits.append({"x": fx, "y": fy, "alive": true, "t": 0.0})
		sources.append(src)
	# Büsche mit roten Beeren
	for bx in [15, 33, 70]:
		var src := {"kind": 1, "trunk": bx, "cx": bx, "cy": SURF - 3, "r": 4, "fruits": [], "blobs": []}
		for b in 5:
			src.blobs.append([r.randf_range(-3.0, 3.0), r.randf_range(-1.5, 1.0), r.randf_range(2.0, 3.2), r.randi_range(0, 2)])
		for f in 4:
			src.fruits.append({"x": clampi(bx + r.randi_range(-3, 3), 1, W - 2), "y": r.randi_range(SURF - 5, SURF - 2), "alive": true, "t": 0.0})
		sources.append(src)
	for i in sources.size():
		source_by_trunk[sources[i].trunk] = i


func rebuild_tiles() -> void:
	ground.clear()
	for y in range(G, H):
		for x in W:
			_update_tile(x, y)


# ---------------------------------------------------------------- Tileset per Code

func _build_tileset() -> TileSet:
	var img := Image.create(16 * T, 12 * T, false, Image.FORMAT_RGBA8)
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	for l in 3:
		for v in 8:
			_paint_soil(img, v, l, l, v, -1, r)
	for l in 2:
		for v in 4:
			_paint_soil(img, l * 4 + v, 3, l + 1, r.randi_range(0, 4), v, r)
	for v in 3:
		for m in 16:
			_paint_hollow(img, m, 4 + v, TUNNEL_COLOR, RIM_COLOR, m, r)
	for ch in range(1, 6):
		for m in 16:
			var base: Color = CHAMBER_COLORS[ch]
			_paint_hollow(img, m, 6 + ch, base, base.lerp(RIM_COLOR, 0.5), m, r)
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(img)
	src.texture_region_size = Vector2i(T, T)
	for row in 12:
		for col in 16:
			src.create_tile(Vector2i(col, row))
	ts.add_source(src, 0)
	return ts


func _paint_soil(img: Image, col: int, row: int, layer: int, variant: int, dash: int, r: RandomNumberGenerator) -> void:
	var base: Color = SOIL_COLORS[layer]
	for py in T:
		for px in T:
			var n := r.randf_range(-0.035, 0.035)
			var c := Color(base.r + n, base.g + n, base.b + n * 0.8)
			if r.randf() < 0.06:
				c = c.lightened(0.12)
			img.set_pixel(col * T + px, row * T + py, c)
	match variant:
		5:
			img.set_pixel(col * T + r.randi_range(0, 2), row * T + r.randi_range(0, 2), base.darkened(0.35))
		6:
			var ox := r.randi_range(0, 1)
			var oy := r.randi_range(0, 1)
			var stone := Color(0.55, 0.52, 0.48)
			img.set_pixel(col * T + ox, row * T + oy, stone.lightened(0.2))
			img.set_pixel(col * T + ox + 1, row * T + oy, stone)
			img.set_pixel(col * T + ox, row * T + oy + 1, stone)
			img.set_pixel(col * T + ox + 1, row * T + oy + 1, stone.darkened(0.25))
		7:
			img.set_pixel(col * T + r.randi_range(0, 2), row * T + r.randi_range(0, 2), base.darkened(0.2))
			img.set_pixel(col * T + r.randi_range(0, 2), row * T + r.randi_range(0, 2), base.lightened(0.2))
	if dash >= 0:
		var line := base.darkened(0.42)
		match dash:
			0:
				for px in 3:
					img.set_pixel(col * T + px, row * T, line)
			1:
				img.set_pixel(col * T, row * T, line)
				img.set_pixel(col * T + 1, row * T, line)
			2:
				img.set_pixel(col * T + 1, row * T + 1, line)
				img.set_pixel(col * T + 2, row * T + 1, line)
			3:
				img.set_pixel(col * T + 2, row * T, line)


func _paint_hollow(img: Image, col: int, row: int, base: Color, rim: Color, mask: int, r: RandomNumberGenerator) -> void:
	for py in T:
		for px in T:
			var n := r.randf_range(-0.03, 0.03)
			var c := Color(base.r + n, base.g + n, base.b + n)
			if r.randf() < 0.1:
				c = c.darkened(0.18)
			var edge := (mask & 1 and py == 0) or (mask & 2 and px == T - 1) \
				or (mask & 4 and py == T - 1) or (mask & 8 and px == 0)
			if edge:
				var k := r.randf()
				if k < 0.45:
					c = rim
				elif k < 0.6:
					c = base.darkened(0.3)
			img.set_pixel(col * T + px, row * T + py, c)


static func hash2(x: int, y: int) -> int:
	var h := x * 374761393 + y * 668265263
	h = (h ^ (h >> 13)) * 1274126177
	return (h ^ (h >> 16)) & 0x7fffffff


static func layer_of(y: int) -> int:
	if y < LAYER_ROWS[1]:
		return 0
	if y < LAYER_ROWS[2]:
		return 1
	return 2


func _soil_tile(x: int, y: int) -> Vector2i:
	var l := layer_of(y)
	var h := hash2(x, y)
	if (y == LAYER_ROWS[1] or y == LAYER_ROWS[2]) and h % 7 != 0:
		return Vector2i((l - 1) * 4 + (h >> 4) % 4, 3)
	var v := h % 100
	var variant := (h >> 5) % 5
	if v >= 98:
		variant = 6
	elif v >= 93:
		variant = 7
	elif v >= 86:
		variant = 5
	return Vector2i(variant, l)


func _solid(x: int, y: int) -> bool:
	if y < G:
		return false
	if x < 0 or x >= W or y >= H:
		return true
	return cells[y * W + x] == SOIL


func _update_tile(x: int, y: int) -> void:
	if x < 0 or x >= W or y < G or y >= H:
		return
	var i := y * W + x
	var c := cells[i]
	if c == SOIL:
		ground.set_cell(Vector2i(x, y), 0, _soil_tile(x, y))
	elif c == TUNNEL:
		var m := 0
		if _solid(x, y - 1):
			m |= 1
		if _solid(x + 1, y):
			m |= 2
		if _solid(x, y + 1):
			m |= 4
		if _solid(x - 1, y):
			m |= 8
		var ch := chamber[i]
		var row := 4 + hash2(x, y) % 3 if ch == 0 else 6 + ch
		ground.set_cell(Vector2i(x, y), 0, Vector2i(m, row))
	else:
		ground.erase_cell(Vector2i(x, y))


# ---------------------------------------------------------------- Abfragen

func idx(x: int, y: int) -> int:
	return y * W + x


func in_grid(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < W and y < H


func cell(x: int, y: int) -> int:
	if not in_grid(x, y):
		return SOIL
	return cells[y * W + x]


func is_tunnel(x: int, y: int) -> bool:
	return in_grid(x, y) and cells[y * W + x] == TUNNEL


func chamber_at(x: int, y: int) -> int:
	if not in_grid(x, y):
		return 0
	return chamber[y * W + x]


static func cell_center(x: int, y: int) -> Vector2:
	return Vector2(x * T + 1.5, y * T + 1.5)


func dig_time(y: int) -> float:
	return 0.45 + 0.2 * layer_of(y)


func dig(x: int, y: int) -> void:
	if not in_grid(x, y) or y < G:
		return
	var i := y * W + x
	if cells[i] != SOIL:
		return
	cells[i] = TUNNEL
	if chamber[i] != 0:
		chamber_cells[chamber[i]].append(i)
	_update_tile(x, y)
	_update_tile(x - 1, y)
	_update_tile(x + 1, y)
	_update_tile(x, y - 1)
	_update_tile(x, y + 1)
	mark_all_dirty()


func mark_all_dirty() -> void:
	for f in F_COUNT:
		field_dirty[f] = true


func mark_dirty(fid: int) -> void:
	field_dirty[fid] = true


# ---------------------------------------------------------------- Wegfelder (BFS)

func _field_sources(fid: int) -> PackedInt32Array:
	match fid:
		F_EXIT:
			var e := G * W + ENT
			return PackedInt32Array([e]) if cells[e] == TUNNEL else PackedInt32Array()
		F_GRANARY:
			return chamber_cells[CH_GRANARY]
		F_BROOD:
			return chamber_cells[CH_BROOD]
		F_QUEEN:
			return chamber_cells[CH_QUEEN]
		F_CEMETERY:
			return chamber_cells[CH_CEMETERY]
		F_TRASH:
			return chamber_cells[CH_TRASH]
		F_DIG:
			return main.colony.dig_sources()
		F_CORPSE:
			return main.colony.corpse_sources()
	return PackedInt32Array()


func _compute_field(fid: int) -> void:
	var f: PackedInt32Array = fields[fid]
	f.fill(INF)
	var q := _field_sources(fid)
	var valid := PackedInt32Array()
	for s in q:
		if cells[s] == TUNNEL and f[s] != 0:
			f[s] = 0
			valid.append(s)
	q = valid
	var head := 0
	while head < q.size():
		var i := q[head]
		head += 1
		var d := f[i] + 1
		var x := i % W
		var n := i - W
		if n >= 0 and cells[n] == TUNNEL and f[n] > d:
			f[n] = d
			q.append(n)
		n = i + W
		if n < W * H and cells[n] == TUNNEL and f[n] > d:
			f[n] = d
			q.append(n)
		if x > 0:
			n = i - 1
			if cells[n] == TUNNEL and f[n] > d:
				f[n] = d
				q.append(n)
		if x < W - 1:
			n = i + 1
			if cells[n] == TUNNEL and f[n] > d:
				f[n] = d
				q.append(n)
	fields[fid] = f
	field_has[fid] = valid.size() > 0
	field_dirty[fid] = false


func has_field(fid: int) -> bool:
	if field_dirty[fid]:
		_compute_field(fid)
	return field_has[fid]


func field_value(fid: int, x: int, y: int) -> int:
	if field_dirty[fid]:
		_compute_field(fid)
	if not in_grid(x, y):
		return INF
	return fields[fid][y * W + x]


## Liefert die nächste Zelle Richtung Ziel, ARRIVED am Ziel oder NO_PATH.
func next_step(fid: int, x: int, y: int, rng: RandomNumberGenerator) -> Vector2i:
	if field_dirty[fid]:
		_compute_field(fid)
	if not in_grid(x, y):
		return NO_PATH
	var f: PackedInt32Array = fields[fid]
	var cur := f[y * W + x]
	if cur == 0:
		return ARRIVED
	if cur >= INF:
		return NO_PATH
	var opts: Array[Vector2i] = []
	if y > 0 and f[(y - 1) * W + x] < cur:
		opts.append(Vector2i(x, y - 1))
	if y < H - 1 and f[(y + 1) * W + x] < cur:
		opts.append(Vector2i(x, y + 1))
	if x > 0 and f[y * W + x - 1] < cur:
		opts.append(Vector2i(x - 1, y))
	if x < W - 1 and f[y * W + x + 1] < cur:
		opts.append(Vector2i(x + 1, y))
	if opts.is_empty():
		return NO_PATH
	return opts[rng.randi() % opts.size()]


func random_neighbor(x: int, y: int, rng: RandomNumberGenerator, only_chamber := -1) -> Vector2i:
	var opts: Array[Vector2i] = []
	for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		var nx: int = x + d.x
		var ny: int = y + d.y
		if is_tunnel(nx, ny) and (only_chamber < 0 or chamber[ny * W + nx] == only_chamber):
			opts.append(Vector2i(nx, ny))
	if opts.is_empty():
		return Vector2i(x, y)
	return opts[rng.randi() % opts.size()]


func nearest_tunnel(x: int, y: int, radius := 14) -> Vector2i:
	for r in range(1, radius + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				if is_tunnel(x + dx, y + dy):
					return Vector2i(x + dx, y + dy)
	return Vector2i(ENT, G)


# ---------------------------------------------------------------- Futterquellen

func source_at(x: int) -> int:
	return source_by_trunk.get(x, -1)


func pick_fruit(si: int, rng: RandomNumberGenerator) -> Vector2i:
	var alive: Array = []
	for f in sources[si].fruits:
		if f.alive:
			alive.append(f)
	if alive.is_empty():
		return ARRIVED
	var f: Dictionary = alive[rng.randi() % alive.size()]
	return Vector2i(f.x, f.y)


func has_fruit(si: int) -> bool:
	for f in sources[si].fruits:
		if f.alive:
			return true
	return false


func take_fruit(x: int, y: int) -> bool:
	for s in sources:
		for f in s.fruits:
			if f.alive and f.x == x and f.y == y:
				f.alive = false
				f.t = 0.0
				sky.dirty = true
				return true
	return false


# ---------------------------------------------------------------- Sandhügel

func add_dirt(x: int) -> void:
	x = clampi(x, 2, W - 3)
	if absi(x - ENT) <= 1:
		x = ENT + (2 if x >= ENT else -2)
	mound[x] += 0.8
	for _iter in 4:
		for c in range(2, W - 2):
			if absi(c - ENT) <= 1:
				mound[c] = 0.0
				continue
			for n in [c - 1, c + 1]:
				if absi(n - ENT) <= 1:
					continue
				var diff: float = mound[c] - mound[n]
				if diff > 1.4:
					var mv := (diff - 1.0) * 0.5
					mound[c] -= mv
					mound[n] += mv
	for c in W:
		mound[c] = minf(mound[c], 28.0)
	sky.dirty = true


func surface_offset(x: int) -> float:
	if x < 0 or x >= W:
		return 0.0
	return mound[x]


# ---------------------------------------------------------------- Wasser (zellulärer Automat)

func add_rain(amount: float, rng: RandomNumberGenerator) -> void:
	for k in 8:
		var x := rng.randi_range(1, W - 2)
		var i := SURF * W + x
		water[i] = minf(1.0, water[i] + amount)
	# Regen, der auf den Hügel fällt, läuft in den Eingang
	var e := SURF * W + ENT
	water[e] = minf(1.0, water[e] + amount * 1.5)
	wet = true


func water_at(x: int, y: int) -> float:
	if not in_grid(x, y):
		return 0.0
	return water[y * W + x]


func _water_step() -> void:
	var any := false
	var flip := (_water_frame & 1) == 0
	for y in range(H - 1, SURF - 1, -1):
		var row := y * W
		for k in W:
			var x := k if flip else W - 1 - k
			var i := row + x
			var w := water[i]
			if w < 0.003:
				if w > 0.0:
					water[i] = 0.0
				continue
			any = true
			w -= 0.0012 if y >= G else 0.006
			if w <= 0.0:
				water[i] = 0.0
				continue
			if y + 1 < H and cells[i + W] != SOIL:
				var b := water[i + W]
				var fl := minf(w, 1.0 - b)
				if fl > 0.0:
					water[i + W] = b + fl
					w -= fl
			if w > 0.01:
				if x > 0 and cells[i - 1] != SOIL:
					var l := water[i - 1]
					if l < w:
						var d := (w - l) * 0.3
						water[i - 1] = l + d
						w -= d
				if x < W - 1 and cells[i + 1] != SOIL:
					var rr := water[i + 1]
					if rr < w:
						var d2 := (w - rr) * 0.3
						water[i + 1] = rr + d2
						w -= d2
			water[i] = w
	wet = any


func _water_render() -> void:
	var bytes := PackedByteArray()
	bytes.resize(W * H * 4)
	if wet:
		for i in range(SURF * W, W * H):
			var w := water[i]
			if w < 0.02:
				continue
			var o := i * 4
			bytes[o] = 60
			bytes[o + 1] = 120 + int(w * 30.0)
			bytes[o + 2] = 215
			bytes[o + 3] = int(clampf(90.0 + w * 140.0, 0.0, 230.0))
	_water_img.set_data(W, H, false, Image.FORMAT_RGBA8, bytes)
	_water_tex.update(_water_img)
	_water_shown = wet


# ---------------------------------------------------------------- Takt

func tick(dt: float) -> void:
	var done := 0
	for f in F_COUNT:
		if field_dirty[f] and done < 3:
			_compute_field(f)
			done += 1
	for s in sources:
		for f in s.fruits:
			if not f.alive:
				f.t += dt
				if f.t > 32.0:
					f.alive = true
					sky.dirty = true
	_water_frame += 1
	if wet and _water_frame % 3 == 0:
		_water_step()
	if (wet or _water_shown) and _water_frame % 6 == 0:
		_water_render()


# ---------------------------------------------------------------- Rahmen

func _draw_frame() -> void:
	var w := W * T
	var h := H * T
	var outer := Color(0.10, 0.25, 0.14)
	var light := Color(0.20, 0.42, 0.26)
	var dark := Color(0.05, 0.14, 0.08)
	var f := FRAME
	frame_node.draw_rect(Rect2(-f, -f, w + 2 * f, f), outer)
	frame_node.draw_rect(Rect2(-f, h, w + 2 * f, f), outer)
	frame_node.draw_rect(Rect2(-f, 0, f, h), outer)
	frame_node.draw_rect(Rect2(w, 0, f, h), outer)
	frame_node.draw_rect(Rect2(-f, -f, w + 2 * f, 1), light)
	frame_node.draw_rect(Rect2(-f, -f, 1, h + 2 * f), light)
	frame_node.draw_rect(Rect2(-1, -1, w + 2, 1), dark)
	frame_node.draw_rect(Rect2(-1, -1, 1, h + 2), dark)
	frame_node.draw_rect(Rect2(-1, h, w + 2, 1), light)
	frame_node.draw_rect(Rect2(w, -1, 1, h + 2), light)
	frame_node.draw_rect(Rect2(-f, h + f - 1, w + 2 * f, 1), dark)
	frame_node.draw_rect(Rect2(w + f - 1, -f, 1, h + 2 * f), dark)
	for p in [Vector2(-3, -3), Vector2(w + 2, -3), Vector2(-3, h + 2), Vector2(w + 2, h + 2)]:
		frame_node.draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(0.55, 0.6, 0.5))
		frame_node.draw_rect(Rect2(p - Vector2(1, 1), Vector2(1, 1)), Color(0.8, 0.85, 0.75))
	# Glas: zarte Spiegelung
	var glare := Color(1, 1, 1, 0.05)
	for k in 3:
		var x0 := 30.0 + k * 9.0
		frame_node.draw_line(Vector2(x0, h), Vector2(x0 + 160.0, h - 300.0), glare, 2.0 - k * 0.5)


# ---------------------------------------------------------------- Speichern

func to_dict() -> Dictionary:
	var fruits: Array = []
	for s in sources:
		for f in s.fruits:
			fruits.append([1 if f.alive else 0, snappedf(f.t, 0.1)])
	return {
		"seed": seed_value,
		"cells": Marshalls.raw_to_base64(cells),
		"chamber": Marshalls.raw_to_base64(chamber),
		"mound": Array(mound),
		"fruits": fruits,
	}


func from_dict(d: Dictionary) -> bool:
	var c := Marshalls.base64_to_raw(d.get("cells", ""))
	var ch := Marshalls.base64_to_raw(d.get("chamber", ""))
	if c.size() != W * H or ch.size() != W * H:
		return false
	seed_value = int(d.get("seed", 1))
	cells = c
	chamber = ch
	water.resize(W * H)
	mound.resize(W)
	mound.fill(0.0)
	var m: Array = d.get("mound", [])
	for x in mini(m.size(), W):
		mound[x] = float(m[x])
	_generate_sources()
	var fr: Array = d.get("fruits", [])
	var k := 0
	for s in sources:
		for f in s.fruits:
			if k < fr.size():
				f.alive = int(fr[k][0]) == 1
				f.t = float(fr[k][1])
			k += 1
	_reset_runtime()
	rebuild_tiles()
	return true
