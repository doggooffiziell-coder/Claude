extends Node2D
## Leuchte am Mast. Additiv, ohne Abdunklung.

static var _add_mat: CanvasItemMaterial

var builder: Node


func _ready() -> void:
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = _add_mat


var _was := false


func _process(_delta: float) -> void:
	if builder == null:
		return
	var on: bool = float(builder.night) > 0.01
	if on or _was:
		queue_redraw()
	_was = on


func _draw() -> void:
	if builder == null:
		return
	var n: float = builder.night
	if n <= 0.01:
		return
	draw_rect(Rect2(4, -12, 2, 1), Color(n, n, n * 0.9, 1.0))
	draw_rect(Rect2(3, -11, 4, 1), Color(n * 0.6, n * 0.5, n * 0.25, 1.0))
	draw_rect(Rect2(4, -10, 2, 1), Color(n * 0.35, n * 0.28, n * 0.12, 1.0))
