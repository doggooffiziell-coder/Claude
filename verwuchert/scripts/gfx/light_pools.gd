class_name LightPools
extends Node2D
## Warme Lichtkegel auf dem Boden: unter Laternen, vor erleuchteten Fenstern, im Park.
## Additiv und ohne Abdunklung, damit die Nacht wirklich leuchtet.

var builder: Node
var _pool_tex: ImageTexture


func _ready() -> void:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	_pool_tex = _make_pool(40, 22)


## Ovaler Lichtfleck mit gerastertem Rand, damit er pixelig bleibt.
static func _make_pool(w: int, h: int) -> ImageTexture:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var d := Vector2((x + 0.5 - w * 0.5) / (w * 0.5), (y + 0.5 - h * 0.5) / (h * 0.5)).length()
			if d > 1.0:
				continue
			var v := 1.0 - d
			var level := 0.0
			if v > 0.55:
				level = 0.30
			elif v > 0.3:
				level = 0.2 if PixelCanvas.bayer(x, y, 0.75) else 0.12
			elif v > 0.12:
				level = 0.12 if PixelCanvas.bayer(x, y, 0.5) else 0.0
			else:
				level = 0.08 if PixelCanvas.bayer(x, y, 0.25) else 0.0
			img.set_pixel(x, y, Color(level * 1.0, level * 0.82, level * 0.5, 1.0))
	return ImageTexture.create_from_image(img)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if builder == null:
		return
	var n: float = builder.night
	if n < 0.02:
		return
	var tint := Color(n, n, n, 1.0)
	var size := Vector2(_pool_tex.get_width(), _pool_tex.get_height())
	for lv in builder.lamp_views:
		draw_texture(_pool_tex, lv.position + Vector2(4, 0) - size * 0.5, tint)
	for v in builder.building_views.values():
		var b: Dictionary = v.data
		if b.state != "done":
			continue
		var on := false
		match b.type:
			"house": on = v.status.get("occupied", false)
			"shop", "factory": on = v.status.get("active", false)
			"park": on = true
			"power_plant": on = true
		if not on:
			continue
		var fp: Rect2 = v.footprint()
		var front := Vector2(fp.get_center().x, fp.end.y - 3)
		var k := 0.6 if b.type == "house" else 0.85
		draw_texture(_pool_tex, front - size * 0.5, Color(n * k, n * k, n * k, 1.0))
		if b.type == "park":
			for lp in v.art.get("lamp", []):
				var p: Vector2 = v.position + Vector2(0, -v.art.size.y) + lp
				draw_texture(_pool_tex, p - size * 0.5, tint)
