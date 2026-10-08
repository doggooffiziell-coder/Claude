class_name MenuTitle
extends Node2D
## Der Titel als Blockschrift mit Tiefe. Jeder Schriftpixel wird diagonal im 2:1-Winkel
## nach rechts unten gezogen, so passt er zur isometrischen Insel. Auf den Buchstaben
## wachsen nach und nach Ranken.

const TITLE := "Verwuchert"
const SCALE := 4
const DEPTH := 7
const STEP := Vector2i(2, 1)

var _tex: ImageTexture
var _width := 0
var _vines: Array = []
var _t := 0.0
var _font: Font


func _ready() -> void:
	_font = PixelFont.font()
	var mask := PixelFont.text_mask(TITLE, SCALE)
	_width = mask.get_width()
	_tex = ImageTexture.create_from_image(_paint(mask))
	_grow_vines(mask)


func _paint(mask: Image) -> Image:
	var mw := mask.get_width()
	var mh := mask.get_height()
	var c := PixelCanvas.new(mw + DEPTH * STEP.x + 8, mh + DEPTH * STEP.y + 8)
	var solid := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < mw and y < mh and mask.get_pixel(x, y).a > 0.0
	var ramp := [Pal.STONE, Pal.STONE_D, Pal.STONE_D, Pal.SLATE, Pal.SLATE, Pal.NIGHT, Pal.NIGHT, Pal.BLACK]
	# Tiefe von hinten nach vorn: die hintersten Schichten zuerst
	for k in range(DEPTH, 0, -1):
		var col: Color = ramp[mini(k - 1, ramp.size() - 1)]
		for y in mh:
			for x in mw:
				if not solid.call(x, y):
					continue
				var shade := col
				# Rechte Flächen etwas dunkler als die untere Kante
				if not solid.call(x + 1, y) and PixelCanvas.bayer(x, y, 0.5):
					shade = Shade.dark(col)
				c.px(x + k * STEP.x + 1, y + k * STEP.y + 1, shade)
	# Vorderseite mit Verlauf, helle Kante oben links, dunkle unten rechts
	var base := PixelFont.ASCENT * SCALE
	for y in mh:
		var t := clampf(float(y) / float(base), 0.0, 1.0)
		for x in mw:
			if not solid.call(x, y):
				continue
			var col := Pal.WHITE
			if t > 0.78:
				col = Pal.SAND if PixelCanvas.bayer(x, y, (t - 0.78) * 4.5) else Pal.BONE
			elif t > 0.42:
				col = Pal.BONE if PixelCanvas.bayer(x, y, (t - 0.42) * 2.8) else Pal.WHITE
			if not solid.call(x, y - 1) or not solid.call(x - 1, y):
				col = Pal.WHITE
			if not solid.call(x, y + 1) or not solid.call(x + 1, y):
				col = Pal.SAND
			c.px(x + 1, y + 1, col)
	c.outline(Pal.NIGHT)
	# Moos auf den Unterkanten
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 320:
		var x := rng.randi_range(0, mw - 1)
		var y := rng.randi_range(int(base * 0.55), base - 1)
		if solid.call(x, y) and not solid.call(x, y + 2):
			c.px(x + 1, y + 1, Pal.GRASS if rng.randf() < 0.6 else Pal.MOSS)
			if rng.randf() < 0.4:
				c.px(x + 1, y, Pal.GRASS_L)
	return c.img


## Ranken wachsen von den Oberkanten der Buchstaben nach unten.
func _grow_vines(mask: Image) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var tries := 0
	while _vines.size() < 10 and tries < 300:
		tries += 1
		var x := rng.randi_range(4, mask.get_width() - 4)
		# Von der Unterkante der Buchstaben aus nach unten, damit die Vorderseite frei bleibt
		var y := mask.get_height() - 1
		while y >= 0 and mask.get_pixel(x, y).a == 0.0:
			y -= 1
		if y < 0:
			continue
		var pts: Array[Vector2i] = []
		var cur := Vector2i(x + 1, y + 1)
		var drift := rng.randf_range(-0.4, 0.4)
		for s in rng.randi_range(10, 26):
			pts.append(cur)
			cur.y += 1
			if rng.randf() < absf(drift) + 0.15:
				cur.x += 1 if (drift > 0.0 or rng.randf() < 0.3) else -1
		_vines.append({"pts": pts, "delay": rng.randf_range(0.2, 2.2), "seed": rng.randi()})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_texture(_tex, Vector2(-1, -1))
	for v in _vines:
		var grow := clampf((_t - float(v.delay)) * 16.0, 0.0, float(v.pts.size()))
		for i in int(grow):
			var p: Vector2i = v.pts[i]
			draw_rect(Rect2(Vector2(p), Vector2.ONE), Pal.MOSS if i % 4 else Pal.GRASS)
			if i % 4 == 1:
				var side := 1 if (i / 4) % 2 == 0 else -2
				draw_rect(Rect2(Vector2(p) + Vector2(side, 0), Vector2(2, 1)), Pal.GRASS_L)
				draw_rect(Rect2(Vector2(p) + Vector2(side, -1), Vector2(1, 1)), Pal.LEAF_L)
		if grow >= v.pts.size() and int(v.seed) % 3 == 0:
			var end := Vector2(v.pts[v.pts.size() - 1])
			draw_rect(Rect2(end + Vector2(-1, 1), Vector2(3, 1)), Pal.ROSE)
			draw_rect(Rect2(end + Vector2(0, 0), Vector2(1, 3)), Pal.ROSE)
			draw_rect(Rect2(end + Vector2(0, 1), Vector2(1, 1)), Pal.YELLOW)
	var y := PixelFont.ASCENT * SCALE + DEPTH * STEP.y + 14
	draw_string(_font, Vector2(3, y + 1), "Bau eine Stadt. Lass sie 50 Jahre verwuchern.", HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE, Pal.BLACK)
	draw_string(_font, Vector2(2, y), "Bau eine Stadt. Lass sie 50 Jahre verwuchern.", HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE, Pal.SAND)
	draw_string(_font, Vector2(3, y + 13), "Überlebe in ihren Ruinen.", HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE, Pal.BLACK)
	draw_string(_font, Vector2(2, y + 12), "Überlebe in ihren Ruinen.", HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE, Pal.SAND)
