extends Node2D
## Leuchtender Kopf der Laterne. Additiv, ohne Abdunklung.

static var _add_mat: CanvasItemMaterial

var builder: Node


func _ready() -> void:
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = _add_mat


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if builder == null:
		return
	var n: float = builder.night
	if n <= 0.01:
		return
	draw_rect(Rect2(3, -14, 2, 1), Color(n, n, n * 0.9, 1.0))
	draw_rect(Rect2(2, -13, 4, 1), Pal.a(Pal.YELLOW * n, 1.0) * Color(1, 1, 1, 0.6))
	draw_rect(Rect2(3, -12, 2, 1), Pal.a(Pal.OCHRE * n, 1.0) * Color(1, 1, 1, 0.4))
