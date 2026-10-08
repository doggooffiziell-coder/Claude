extends Node2D
## Scheinwerfer und Rücklichter in der Nacht.

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
	var face: int = car.face
	var size := VehicleArt.car_size(face)
	var off := Vector2(-size.x / 2, -size.y + 2)
	var head := Color(n, n * 0.95, n * 0.7, 1.0)
	var beam := Color(n * 0.35, n * 0.32, n * 0.2, 1.0)
	var tail := Color(n * 0.8, n * 0.15, n * 0.1, 1.0)
	match face:
		0:
			draw_rect(Rect2(off + Vector2(12, 4), Vector2(1, 1)), head)
			for k in 6:
				draw_rect(Rect2(off + Vector2(14 + k, 4 - k / 3), Vector2(1, 1 + (k / 3) * 2)), beam * Color(1, 1, 1, 1.0 - k / 6.0))
			draw_rect(Rect2(off + Vector2(1, 4), Vector2(1, 1)), tail)
		2:
			draw_rect(Rect2(off + Vector2(1, 4), Vector2(1, 1)), head)
			for k in 6:
				draw_rect(Rect2(off + Vector2(-1 - k, 4 - k / 3), Vector2(1, 1 + (k / 3) * 2)), beam * Color(1, 1, 1, 1.0 - k / 6.0))
			draw_rect(Rect2(off + Vector2(12, 4), Vector2(1, 1)), tail)
		1:
			draw_rect(Rect2(off + Vector2(1, 10), Vector2(1, 1)), head)
			draw_rect(Rect2(off + Vector2(7, 10), Vector2(1, 1)), head)
			for k in 6:
				draw_rect(Rect2(off + Vector2(1 - k / 3, 12 + k), Vector2(7 + (k / 3) * 2, 1)), beam * Color(1, 1, 1, 1.0 - k / 6.0))
		3:
			draw_rect(Rect2(off + Vector2(1, 10), Vector2(1, 1)), tail)
			draw_rect(Rect2(off + Vector2(7, 10), Vector2(1, 1)), tail)
