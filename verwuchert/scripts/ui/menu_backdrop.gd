extends Node2D
## Hintergrund des Hauptmenüs. Abendhimmel, Häuser mit Ranken, Glühwürmchen, wachsende Ranken am Titel.

const W := 640
const H := 360
const GROUND := 300
const TITLE := "Verwuchert"
const TITLE_SIZE := 36
const TITLE_POS := Vector2(40, 34)

var _sky: ImageTexture
var _scene: ImageTexture
var _title: ImageTexture
var _title_size := Vector2.ZERO
var _vines: Array = []
var _stars: Array[Vector3] = []
var _flies: Array[Dictionary] = []
var _leaves: Array[Dictionary] = []
var _t := 0.0
var _font: Font


func _ready() -> void:
	_font = PixelFont.font()
	_sky = ImageTexture.create_from_image(_paint_sky())
	_scene = ImageTexture.create_from_image(_paint_scene())
	_title = ImageTexture.create_from_image(_paint_title())
	_title_size = Vector2(_title.get_width(), _title.get_height())
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 40:
		_stars.append(Vector3(rng.randi_range(0, W), rng.randi_range(0, 120), rng.randf() * TAU))
	for i in 14:
		_flies.append({"p": Vector2(rng.randf_range(200, 630), rng.randf_range(250, 330)), "ph": rng.randf() * TAU, "sp": rng.randf_range(0.5, 1.2)})
	_build_vines(rng)


func _paint_sky() -> Image:
	var img := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	var bands := [
		[0, Pal.NIGHT], [70, Pal.BLUE_D], [140, Pal.PLUM], [200, Pal.ROSE], [240, Pal.BRICK_L], [270, Pal.OCHRE],
	]
	for y in H:
		var a: Array = bands[0]
		var b: Array = bands[bands.size() - 1]
		for i in bands.size() - 1:
			if y >= bands[i][0] and y < bands[i + 1][0]:
				a = bands[i]
				b = bands[i + 1]
				break
		var t := 0.0
		if b[0] != a[0]:
			t = clampf(float(y - a[0]) / float(b[0] - a[0]), 0.0, 1.0)
		for x in W:
			var col: Color = b[1] if PixelCanvas.bayer(x, y, t) else a[1]
			if y >= bands[bands.size() - 1][0]:
				col = bands[bands.size() - 1][1]
			img.set_pixel(x, y, col)
	return img


func _paint_scene() -> Image:
	var c := PixelCanvas.new(W, H)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	# Ferne Hügel
	for x in W:
		var hy := 250 + int(sin(x * 0.013) * 10.0 + sin(x * 0.041) * 4.0)
		c.vline(x, hy, H - hy, Pal.PLUM)
	# Wald am Horizont
	for x in W:
		var hy := 268 + int(sin(x * 0.05) * 3.0 + sin(x * 0.17 + 1.0) * 3.0 + (rng.randf() * 3.0))
		c.vline(x, hy, H - hy, Pal.MOSS_D)
	for i in 26:
		var x := rng.randi_range(0, W)
		var hgt := rng.randi_range(14, 28)
		c.poly(PackedVector2Array([Vector2(x - 6, 276), Vector2(x, 276 - hgt), Vector2(x + 6, 276)]), Pal.MOSS_D)
	# Häuserzeile rechts, schon ein wenig verwuchert
	var x0 := 250
	var items := [["house", 11, "ziegel"], ["shop", 5, "ziegel"], ["house", 8, "holz"], ["water_tower", 3, "stahl"], ["house", 2, "ziegel"], ["house", 19, "holz"]]
	for it in items:
		var art := BuildingArt.make(it[0], it[1], it[2])
		var img: Image = (art.tex as ImageTexture).get_image()
		var y := GROUND + 6 - img.get_height()
		c.stamp(img, x0, y)
		_overgrow(c, rng, x0, y, img.get_width(), img.get_height())
		x0 += img.get_width() - rng.randi_range(4, 12)
	# Boden
	for y in range(GROUND, H):
		for x in W:
			var col := Pal.MOSS if (y - GROUND) < 4 else Pal.MOSS_D
			if PixelCanvas.bayer(x, y, 0.3) and y - GROUND < 10:
				col = Pal.GRASS
			c.px(x, y, col)
	for i in 900:
		var x := rng.randi_range(0, W - 1)
		var y := rng.randi_range(GROUND - 2, H - 1)
		c.px(x, y, Pal.GRASS if rng.randf() < 0.6 else Pal.MOSS)
		c.px(x, y - 1, Pal.GRASS_L if rng.randf() < 0.3 else Pal.GRASS)
	# Bäume im Vordergrund
	for p in [Vector2(220, GROUND + 10), Vector2(600, GROUND + 14), Vector2(470, GROUND + 18)]:
		var tr := NatureArt.oak(int(p.x))
		var timg: Image = (tr.tex as ImageTexture).get_image()
		c.stamp(timg, int(p.x - tr.foot.x), int(p.y - tr.foot.y))
	return c.img


## Ranken und Moos auf einem Gebäude: wächst von unten an den Wänden hoch.
func _overgrow(c: PixelCanvas, rng: RandomNumberGenerator, x: int, y: int, w: int, h: int) -> void:
	for k in rng.randi_range(3, 6):
		var vx := x + rng.randi_range(2, w - 3)
		var vy := y + h - 3
		var len := rng.randi_range(12, int(h * 0.7))
		for s in len:
			if not c.is_solid(vx, vy):
				break
			c.px(vx, vy, Pal.MOSS if s % 3 else Pal.GRASS)
			if s % 3 == 0:
				c.px(vx + (1 if s % 2 else -1), vy, Pal.GRASS_L)
			vy -= 1
			if rng.randf() < 0.3:
				vx += rng.randi_range(-1, 1)
	for i in w * 2:
		var px := x + rng.randi_range(0, w - 1)
		var py := y + h - rng.randi_range(1, 8)
		if c.is_solid(px, py):
			c.px(px, py, Pal.MOSS if rng.randf() < 0.5 else Pal.GRASS)


## Großer Titel mit feiner Kante: Verlauf, Lichtkante oben, dunkle Kontur, Schlagschatten.
func _paint_title() -> Image:
	const S := 4
	var mask := PixelFont.text_mask(TITLE, S)
	var w := mask.get_width() + 4
	var h := mask.get_height() + 4
	var c := PixelCanvas.new(w, h)
	var solid := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < mask.get_width() and y < mask.get_height() and mask.get_pixel(x, y).a > 0.0
	var top := 0
	var bottom := PixelFont.ASCENT * S
	# Schatten
	for y in mask.get_height():
		for x in mask.get_width():
			if solid.call(x, y):
				c.px(x + 3, y + 3, Pal.BLACK)
	# Füllung mit Verlauf
	for y in mask.get_height():
		var t := float(y - top) / float(bottom - top)
		for x in mask.get_width():
			if not solid.call(x, y):
				continue
			var col := Pal.WHITE
			if t > 0.75:
				col = Pal.SAND if PixelCanvas.bayer(x, y, (t - 0.75) * 4.0) else Pal.BONE
			elif t > 0.4:
				col = Pal.BONE if PixelCanvas.bayer(x, y, (t - 0.4) * 2.8) else Pal.WHITE
			c.px(x + 1, y + 1, col)
	# Lichtkante oben links, Kontur
	for y in mask.get_height():
		for x in mask.get_width():
			if not solid.call(x, y):
				continue
			if not solid.call(x, y - 1) or not solid.call(x - 1, y):
				c.px(x + 1, y + 1, Pal.WHITE)
			if not solid.call(x, y + 1) or not solid.call(x + 1, y):
				c.px(x + 1, y + 1, Pal.SAND)
	c.outline(Pal.NIGHT)
	# Moos in den unteren Ecken der Buchstaben
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 260:
		var x := rng.randi_range(0, mask.get_width() - 1)
		var y := rng.randi_range(int(bottom * 0.6), bottom - 1)
		if solid.call(x, y) and not solid.call(x, y + 2):
			c.px(x + 1, y + 1, Pal.GRASS if rng.randf() < 0.6 else Pal.MOSS)
			if rng.randf() < 0.4:
				c.px(x + 1, y, Pal.GRASS_L)
	return c.img


## Ranken hängen vom Titel herab. Jede Ranke wächst Pixel für Pixel.
func _build_vines(rng: RandomNumberGenerator) -> void:
	var tw := float(PixelFont.text_mask(TITLE, 4).get_width())
	for i in 9:
		var p := TITLE_POS + Vector2(rng.randf_range(4, tw - 4), rng.randf_range(0, 6))
		var pts: Array[Vector2i] = []
		var cur := Vector2i(p)
		var drift := rng.randf_range(-0.4, 0.4)
		var len := rng.randi_range(22, 44)
		for s in len:
			pts.append(cur)
			cur.y += 1
			if rng.randf() < absf(drift) + 0.15:
				cur.x += 1 if (drift > 0.0 or rng.randf() < 0.3) else -1
		_vines.append({"pts": pts, "delay": rng.randf_range(0.0, 1.6), "seed": rng.randi()})


func _process(delta: float) -> void:
	_t += delta
	if randf() < delta * 1.4:
		_leaves.append({"p": Vector2(randf_range(0, W), -4), "v": Vector2(randf_range(6, 14), randf_range(10, 16)), "ph": randf() * TAU,
			"c": [Pal.GRASS_L, Pal.OCHRE, Pal.LEAF_L, Pal.RUST][randi() % 4]})
	for l in _leaves:
		l.p += (l.v + Vector2(sin(_t * 2.0 + l.ph) * 10.0, 0)) * delta
	_leaves = _leaves.filter(func(l): return l.p.y < H)
	queue_redraw()


func _draw() -> void:
	draw_texture(_sky, Vector2.ZERO)
	for s in _stars:
		var v := sin(_t * 1.5 + s.z)
		if v > 0.2:
			draw_rect(Rect2(s.x, s.y, 1, 1), Pal.a(Pal.BONE, 0.4 + v * 0.5))
	draw_texture(_scene, Vector2.ZERO, Color(0.86, 0.76, 0.8))
	# Glühwürmchen
	for f in _flies:
		var p: Vector2 = f.p + Vector2(sin(_t * f.sp + f.ph) * 12.0, cos(_t * f.sp * 1.3 + f.ph) * 5.0)
		var glow := sin(_t * 3.0 + f.ph) * 0.5 + 0.5
		draw_rect(Rect2(p.round(), Vector2.ONE), Pal.a(Pal.YELLOW, 0.3 + glow * 0.7))
		if glow > 0.7:
			draw_rect(Rect2(p.round() + Vector2(-1, 0), Vector2(3, 1)), Pal.a(Pal.YELLOW, 0.25))
			draw_rect(Rect2(p.round() + Vector2(0, -1), Vector2(1, 3)), Pal.a(Pal.YELLOW, 0.25))
	for l in _leaves:
		var flip := int(_t * 6.0 + l.ph) % 2 == 0
		draw_rect(Rect2((l.p as Vector2).round(), Vector2(2 if flip else 1, 1)), l.c)
	draw_texture(_title, TITLE_POS - Vector2(1, 1))
	# Ranken
	for v in _vines:
		var grow := clampf((_t - float(v.delay)) * 18.0, 0.0, float(v.pts.size()))
		for i in int(grow):
			var p: Vector2i = v.pts[i]
			draw_rect(Rect2(Vector2(p), Vector2.ONE), Pal.MOSS if i % 4 else Pal.GRASS)
			if i % 4 == 1:
				var side := 1 if (i / 4) % 2 == 0 else -2
				draw_rect(Rect2(Vector2(p) + Vector2(side, 0), Vector2(2, 1)), Pal.GRASS_L)
				draw_rect(Rect2(Vector2(p) + Vector2(side, -1), Vector2(1, 1)), Pal.LEAF_L)
		# Blüte am Ende
		if grow >= v.pts.size():
			var end: Vector2 = Vector2(v.pts[v.pts.size() - 1])
			if int(v.seed) % 3 == 0:
				draw_rect(Rect2(end + Vector2(-1, 1), Vector2(3, 1)), Pal.ROSE)
				draw_rect(Rect2(end + Vector2(0, 0), Vector2(1, 3)), Pal.ROSE)
				draw_rect(Rect2(end + Vector2(0, 1), Vector2(1, 1)), Pal.YELLOW)
	# Untertitel
	draw_string(_font, TITLE_POS + Vector2(2, 48), "Bau eine Stadt. Lass sie 50 Jahre verwuchern. Überlebe in ihren Ruinen.", HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE, Pal.SAND)
