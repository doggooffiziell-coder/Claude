class_name PixelCanvas
extends RefCounted
## Kleine Malfläche für Pixel-Art. Alle Sprites des Spiels entstehen hier im Code.

const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

var img: Image
var w: int
var h: int


func _init(width: int, height: int) -> void:
	w = width
	h = height
	img = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)


func inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y < h


func get_px(x: int, y: int) -> Color:
	if not inside(x, y):
		return Color(0, 0, 0, 0)
	return img.get_pixel(x, y)


func is_solid(x: int, y: int) -> bool:
	return get_px(x, y).a > 0.0


func px(x: int, y: int, c: Color) -> void:
	if not inside(x, y):
		return
	if c.a >= 1.0:
		img.set_pixel(x, y, c)
	elif c.a > 0.0:
		img.set_pixel(x, y, img.get_pixel(x, y).blend(c))


## Malt nur dort, wo schon etwas ist. Für Schatten und Licht auf Flächen.
func px_on(x: int, y: int, c: Color) -> void:
	if is_solid(x, y):
		px(x, y, c)


func rect(x: int, y: int, rw: int, rh: int, c: Color) -> void:
	if rw <= 0 or rh <= 0:
		return
	if c.a >= 1.0:
		var r := Rect2i(x, y, rw, rh).intersection(Rect2i(0, 0, w, h))
		if r.size.x > 0 and r.size.y > 0:
			img.fill_rect(r, c)
		return
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			px(xx, yy, c)


func clear(x: int, y: int, rw: int, rh: int) -> void:
	var r := Rect2i(x, y, rw, rh).intersection(Rect2i(0, 0, w, h))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, Color(0, 0, 0, 0))


func hline(x: int, y: int, length: int, c: Color) -> void:
	rect(x, y, length, 1, c)


func vline(x: int, y: int, length: int, c: Color) -> void:
	rect(x, y, 1, length, c)


func frame(x: int, y: int, rw: int, rh: int, c: Color) -> void:
	hline(x, y, rw, c)
	hline(x, y + rh - 1, rw, c)
	vline(x, y, rh, c)
	vline(x + rw - 1, y, rh, c)


func line(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		px(x0, y0, c)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


func ellipse(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			if nx * nx + ny * ny <= 1.0:
				px(x, y, c)


func disc(cx: float, cy: float, r: float, c: Color) -> void:
	ellipse(cx, cy, r, r, c)


## Füllt ein Polygon. Punkte als Vector2.
func poly(points: PackedVector2Array, c: Color) -> void:
	var r := Rect2(points[0], Vector2.ZERO)
	for p in points:
		r = r.expand(p)
	for y in range(int(r.position.y), int(r.end.y) + 1):
		for x in range(int(r.position.x), int(r.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				px(x, y, c)


## Geordnetes Raster. density 0 malt nichts, 1 malt alles.
static func bayer(x: int, y: int, density: float) -> bool:
	return BAYER[(y & 3) * 4 + (x & 3)] < density * 16.0


func dither(x: int, y: int, rw: int, rh: int, c: Color, density: float) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			if bayer(xx, yy, density):
				px(xx, yy, c)


func dither_on(x: int, y: int, rw: int, rh: int, c: Color, density: float) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			if bayer(xx, yy, density) and is_solid(xx, yy):
				px(xx, yy, c)


func speckle(x: int, y: int, rw: int, rh: int, c: Color, chance: float, rng: RandomNumberGenerator) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			if rng.randf() < chance:
				px(xx, yy, c)


func speckle_on(x: int, y: int, rw: int, rh: int, c: Color, chance: float, rng: RandomNumberGenerator) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			if rng.randf() < chance and is_solid(xx, yy):
				px(xx, yy, c)


## Ersetzt eine Farbe durch eine andere in einem Bereich.
func recolor(x: int, y: int, rw: int, rh: int, from: Color, to: Color) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			if inside(xx, yy) and img.get_pixel(xx, yy).is_equal_approx(from):
				img.set_pixel(xx, yy, to)


## Dunkle Kontur um alle gemalten Pixel. Unten und rechts kräftiger, oben und links weicher.
func outline(c: Color, soft: Color = Color(0, 0, 0, 0)) -> void:
	var src := img.duplicate()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.0:
				continue
			var below: bool = y > 0 and src.get_pixel(x, y - 1).a > 0.0
			var left: bool = x > 0 and src.get_pixel(x - 1, y).a > 0.0
			var above: bool = y < h - 1 and src.get_pixel(x, y + 1).a > 0.0
			var right: bool = x < w - 1 and src.get_pixel(x + 1, y).a > 0.0
			if below or left:
				img.set_pixel(x, y, c)
			elif (above or right):
				img.set_pixel(x, y, soft if soft.a > 0.0 else c)


## Kopiert ein anderes Bild an eine Stelle, transparente Pixel bleiben frei.
func stamp(other: Image, x: int, y: int) -> void:
	for yy in other.get_height():
		for xx in other.get_width():
			var c := other.get_pixel(xx, yy)
			if c.a > 0.0:
				px(x + xx, y + yy, c)


func texture() -> ImageTexture:
	return ImageTexture.create_from_image(img)
