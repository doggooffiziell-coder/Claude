class_name MenuBackdrop
extends Node2D
## Hintergrund des Hauptmenüs: Himmel mit Tageszeit, Sterne, Mond, Glühwürmchen und die Insel.
## Der Himmel überblendet drei fertige Verläufe: Tag, Abendrot und Nacht.

const W := 640
const H := 360

var diorama: MenuDiorama

var _day: ImageTexture
var _dusk: ImageTexture
var _night: ImageTexture
var _shade: ImageTexture
var _stars: Array[Vector3] = []
var _flies: Array[Dictionary] = []
var _t := 0.0


func _ready() -> void:
	_day = _gradient([[0, Pal.BLUE], [130, Pal.WATER], [250, Pal.SKY], [360, Pal.WHITE]])
	_dusk = _gradient([[0, Pal.BLUE_D], [90, Pal.PLUM], [180, Pal.ROSE], [250, Pal.BRICK_L], [320, Pal.OCHRE], [360, Pal.YELLOW]])
	_night = _gradient([[0, Pal.BLACK], [110, Pal.NIGHT], [230, Pal.BLUE_D], [360, Pal.TEAL_D]])
	_shade = _left_shade()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 46:
		_stars.append(Vector3(rng.randi_range(0, W), rng.randi_range(0, 190), rng.randf() * TAU))
	for i in 18:
		_flies.append({"p": Vector2(rng.randf_range(230, 640), rng.randf_range(90, 340)), "ph": rng.randf() * TAU, "sp": rng.randf_range(0.4, 1.0)})
	diorama = MenuDiorama.new()
	add_child(diorama)


## Senkrechter Verlauf mit geordnetem Raster, damit die Stufen pixelig bleiben.
func _gradient(stops: Array) -> ImageTexture:
	var img := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		var a: Array = stops[0]
		var b: Array = stops[stops.size() - 1]
		for i in stops.size() - 1:
			if y >= stops[i][0] and y < stops[i + 1][0]:
				a = stops[i]
				b = stops[i + 1]
				break
		var t := 0.0
		if b[0] != a[0]:
			t = clampf(float(y - a[0]) / float(b[0] - a[0]), 0.0, 1.0)
		for x in W:
			img.set_pixel(x, y, b[1] if PixelCanvas.bayer(x, y, t) else a[1])
	return ImageTexture.create_from_image(img)


## Dunkler Schleier links, damit die Menüpunkte lesbar bleiben.
func _left_shade() -> ImageTexture:
	var w := 320
	var img := Image.create_empty(w, H, false, Image.FORMAT_RGBA8)
	for x in w:
		var f := 1.0 - float(x) / w
		var level := f * f * 0.62
		for y in H:
			var steps := level * 6.0
			var a := floorf(steps) / 6.0
			if PixelCanvas.bayer(x, y, steps - floorf(steps)):
				a += 1.0 / 6.0
			if a > 0.0:
				img.set_pixel(x, y, Color(0.08, 0.07, 0.1, a))
	return ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var hour := diorama.hour
	var n := DayCycle.night(hour)
	# Abendrot um Sonnenauf- und -untergang
	var d := maxf(0.0, 1.0 - minf(absf(hour - 18.9), absf(hour - 6.1)) / 2.2)
	draw_texture(_night, Vector2.ZERO)
	draw_texture(_day, Vector2.ZERO, Color(1, 1, 1, clampf((1.0 - n) * (1.0 - d), 0.0, 1.0)))
	draw_texture(_dusk, Vector2.ZERO, Color(1, 1, 1, d))
	for s in _stars:
		var v := sin(_t * 1.5 + s.z)
		if v > 0.2:
			draw_rect(Rect2(s.x, s.y, 1, 1), Pal.a(Pal.BONE, (0.35 + v * 0.55) * n))
	_draw_moon(n)
	draw_texture(_shade, Vector2.ZERO)
	# Glühwürmchen schweben um die Insel, nachts deutlicher
	for f in _flies:
		var p: Vector2 = f.p + Vector2(sin(_t * f.sp + f.ph) * 14.0, cos(_t * f.sp * 1.3 + f.ph) * 6.0)
		var glow := sin(_t * 3.0 + f.ph) * 0.5 + 0.5
		var a := (0.15 + n * 0.85) * (0.3 + glow * 0.7)
		draw_rect(Rect2(p.round(), Vector2.ONE), Pal.a(Pal.YELLOW, a))
		if glow > 0.75 and n > 0.3:
			draw_rect(Rect2(p.round() + Vector2(-1, 0), Vector2(3, 1)), Pal.a(Pal.YELLOW, 0.25 * n))
			draw_rect(Rect2(p.round() + Vector2(0, -1), Vector2(1, 3)), Pal.a(Pal.YELLOW, 0.25 * n))


func _draw_moon(n: float) -> void:
	if n < 0.05:
		return
	var c := Vector2(366, 44)
	var r := 11.0
	for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
		for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
			var d := Vector2(x + 0.5, y + 0.5) - c
			if d.length() > r:
				continue
			# Sichel: der zweite Kreis schneidet ab
			if (Vector2(x + 0.5, y + 0.5) - (c + Vector2(5.0, -2.0))).length() < r - 1.0:
				continue
			var col := Pal.BONE if d.x + d.y * 0.5 < 0.0 else Pal.WHITE
			draw_rect(Rect2(x, y, 1, 1), Pal.a(col, n))
	draw_rect(Rect2(c.x - 14, c.y - 14, 3, 1), Pal.a(Pal.WHITE, n * 0.5))
