extends Node2D
## Scheinwerfer als Lichtkegel auf der Straße und Rücklichter in der Nacht.

static var _add_mat: CanvasItemMaterial

var car: Node2D


func _ready() -> void:
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = _add_mat


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if car == null or car.builder == null:
		return
	var n: float = car.builder.night
	if n < 0.05:
		return
	var art := VehicleArt.car(car.face, car.body)
	var off: Vector2 = -art.anchor
	var head := Color(n, n * 0.95, n * 0.7, 1.0)
	var tail := Color(n * 0.8, n * 0.15, n * 0.1, 1.0)
	var fwd := Vector2(car.dir)
	# Kegel vor dem Auto auf dem Boden
	var beam := Color(n * 0.28, n * 0.25, n * 0.15, 1.0)
	for k in range(1, 7):
		var g := fwd * (0.2 + k * 0.07)
		var p := Iso.to_screen(g.x, g.y).round()
		var w := 1 + k / 2
		draw_rect(Rect2(p + Vector2(-w, -1), Vector2(w * 2 + 1, 1)), beam * Color(1, 1, 1, 1.0 - k / 7.0))
	var fp: Vector2 = off + art.front
	var bp: Vector2 = off + art.back
	if car.face == 0 or car.face == 1:
		draw_rect(Rect2(fp.round(), Vector2.ONE), head)
	else:
		draw_rect(Rect2(bp.round(), Vector2.ONE), tail)
