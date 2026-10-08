class_name SkyLayer
extends Node2D
## Wolkenschatten ziehen über die Stadt, ab und zu fliegt ein Vogelschwarm vorbei.

var builder: Node
var bounds := Rect2()
var _clouds: Array[Dictionary] = []
var _birds: Array[Dictionary] = []
var _bird_t := 8.0


func setup(city_builder: Node, area: Rect2) -> void:
	builder = city_builder
	bounds = area
	var rng := RandomNumberGenerator.new()
	rng.seed = int(GameState.city.seed) + 99
	for i in 5:
		var tex := _cloud_tex(rng)
		_clouds.append({"tex": tex, "pos": Vector2(rng.randf_range(bounds.position.x, bounds.end.x), rng.randf_range(bounds.position.y, bounds.end.y)), "speed": rng.randf_range(0.7, 1.2)})


static func _cloud_tex(rng: RandomNumberGenerator) -> ImageTexture:
	var w := rng.randi_range(110, 170)
	var h := rng.randi_range(50, 80)
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var blobs := []
	for i in rng.randi_range(5, 8):
		blobs.append([Vector2(rng.randf_range(w * 0.25, w * 0.75), rng.randf_range(h * 0.35, h * 0.65)), rng.randf_range(h * 0.25, h * 0.45)])
	for y in h:
		for x in w:
			var best := 9.0
			for b in blobs:
				var d: float = (Vector2(x, y) - (b[0] as Vector2)).length() / float(b[1])
				best = minf(best, d)
			if best < 0.8:
				img.set_pixel(x, y, Color(0, 0, 0, 0.13))
			elif best < 1.0 and PixelCanvas.bayer(x, y, 0.5):
				img.set_pixel(x, y, Color(0, 0, 0, 0.13))
			elif best < 1.15 and PixelCanvas.bayer(x, y, 0.2):
				img.set_pixel(x, y, Color(0, 0, 0, 0.13))
	return ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	var spd: float = builder.speed if builder else 1.0
	var wind := Vector2(6.0, 1.2)
	for c in _clouds:
		c.pos += wind * c.speed * delta * maxf(spd, 0.3)
		if c.pos.x > bounds.end.x + 40:
			c.pos.x = bounds.position.x - 200
			c.pos.y = randf_range(bounds.position.y, bounds.end.y)
		if c.pos.y > bounds.end.y + 40:
			c.pos.y = bounds.position.y - 100
	_bird_t -= delta * maxf(spd, 0.3)
	if _bird_t <= 0.0 and builder and builder.night < 0.5:
		_bird_t = randf_range(25.0, 50.0)
		_spawn_flock()
	for b in _birds:
		b.pos += b.vel * delta
		b.flap += delta * b.flap_speed
	_birds = _birds.filter(func(b): return bounds.grow(120).has_point(b.pos))
	queue_redraw()


func _spawn_flock() -> void:
	var from_left := randf() < 0.5
	var y := randf_range(bounds.position.y + 40, bounds.end.y - 40)
	var start := Vector2(bounds.position.x - 60 if from_left else bounds.end.x + 60, y)
	var vel := Vector2(28.0 if from_left else -28.0, randf_range(-6, 6))
	var n := randi_range(3, 6)
	for i in n:
		var off := Vector2(-absf(i - n / 2.0) * 7.0 * signf(vel.x), (i - n / 2.0) * 6.0)
		_birds.append({"pos": start + off, "vel": vel, "flap": randf() * 3.0, "flap_speed": randf_range(7.0, 9.0), "alt": 48.0})


func _draw() -> void:
	var sun_s: float = DayCycle.sun_strength(builder.hour) if builder else 1.0
	var day: float = 1.0 - (float(builder.night) if builder else 0.0)
	for c in _clouds:
		draw_texture(c.tex, (c.pos as Vector2).round(), Color(1, 1, 1, 0.4 + 0.6 * sun_s * day))
	var sun: Vector2 = DayCycle.sun_vector(builder.hour) if builder else Vector2.ZERO
	for b in _birds:
		var p: Vector2 = (b.pos as Vector2).round()
		var up := int(b.flap) % 2 == 0
		var shadow: Vector2 = p + Vector2(0, b.alt) + sun * 6.0
		_bird(shadow, up, Pal.a(Pal.BLACK, 0.18 * sun_s))
		_bird(p, up, Pal.NIGHT)


func _bird(p: Vector2, up: bool, col: Color) -> void:
	draw_rect(Rect2(p, Vector2(1, 1)), col)
	if up:
		draw_rect(Rect2(p + Vector2(-2, -1), Vector2(2, 1)), col)
		draw_rect(Rect2(p + Vector2(1, -1), Vector2(2, 1)), col)
	else:
		draw_rect(Rect2(p + Vector2(-2, 0), Vector2(2, 1)), col)
		draw_rect(Rect2(p + Vector2(1, 0), Vector2(2, 1)), col)
		draw_rect(Rect2(p + Vector2(-3, 1), Vector2(1, 1)), col)
		draw_rect(Rect2(p + Vector2(3, 1), Vector2(1, 1)), col)
