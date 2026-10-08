class_name LightPools
extends Node2D
## Warme Lichtkegel auf dem Boden: unter Laternen, vor erleuchteten Türen, im Park.
## Additiv und ohne Abdunklung. Im Bodenraum gemalt, darum liegen sie als Ellipse auf der Raute.

const T := 32

var builder: Node
var _pool_tex: ImageTexture


func _ready() -> void:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	_pool_tex = _make_pool(34)


## Runder Lichtfleck mit gerastertem Rand, damit er pixelig bleibt.
static func _make_pool(d: int) -> ImageTexture:
	var img := Image.create_empty(d, d, false, Image.FORMAT_RGBA8)
	for y in d:
		for x in d:
			var r := Vector2((x + 0.5 - d * 0.5) / (d * 0.5), (y + 0.5 - d * 0.5) / (d * 0.5)).length()
			if r > 1.0:
				continue
			var v := 1.0 - r
			var level := 0.0
			if v > 0.55:
				level = 0.3
			elif v > 0.3:
				level = 0.2 if PixelCanvas.bayer(x, y, 0.75) else 0.12
			elif v > 0.12:
				level = 0.12 if PixelCanvas.bayer(x, y, 0.5) else 0.0
			else:
				level = 0.08 if PixelCanvas.bayer(x, y, 0.25) else 0.0
			img.set_pixel(x, y, Color(level, level * 0.78, level * 0.42, 1.0))
	return ImageTexture.create_from_image(img)


var _acc := 0.0
var _was := false


## Lichtkegel gibt es nur nachts, und zehn Bilder pro Sekunde reichen.
func _process(delta: float) -> void:
	if builder == null:
		return
	_acc += delta
	if _acc < 0.1:
		return
	_acc = 0.0
	var on: bool = float(builder.night) >= 0.02
	if on or _was:
		queue_redraw()
	_was = on


func _draw() -> void:
	if builder == null:
		return
	var n: float = builder.night
	if n < 0.02:
		return
	draw_set_transform_matrix(Iso.GROUND)
	var tint := Color(n, n, n, 1.0)
	var half := Vector2(_pool_tex.get_width(), _pool_tex.get_height()) * 0.5
	for pv in builder.pole_views:
		var c: Vector2 = (Vector2(pv.tile) + Vector2(0.5, 0.5)).lerp(pv.ground_pos, 0.55) * T
		draw_texture(_pool_tex, c - half, tint)
	for v in builder.building_views.values():
		var b: Dictionary = v.data
		if b.state != "done":
			continue
		var on := false
		match b.type:
			"house": on = v.status.get("occupied", false)
			"shop", "factory": on = v.status.get("active", false)
			"park": on = true
		if not on:
			continue
		var door: Vector2 = builder.door_point(b) * T
		var k := 0.55 if b.type == "house" else 0.85
		draw_texture(_pool_tex, door - half, Color(n * k, n * k, n * k, 1.0))
	draw_set_transform_matrix(Transform2D.IDENTITY)
