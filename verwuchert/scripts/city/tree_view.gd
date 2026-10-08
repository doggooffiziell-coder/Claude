class_name TreeView
extends Node2D
## Baum, Busch oder Stein. Die Krone wiegt im Wind, ältere Blätter fallen ab und zu.

var data: Dictionary
var art: Dictionary
var builder: Node
var decor := false
var _leaf_t := 0.0


func setup(t: Dictionary, city_builder: Node, is_decor := false) -> void:
	data = t
	builder = city_builder
	decor = is_decor
	art = SpriteFactory.tree(t.kind, int(t.seed))
	position = Vector2(int(t.x) * 32 + 16 + int(t.get("ox", 0)), int(t.y) * 32 + 24 + int(t.get("oy", 0)))
	use_parent_material = true
	_leaf_t = randf_range(2.0, 12.0)


func tile() -> Vector2i:
	return Vector2i(int(data.x), int(data.y))


func _process(delta: float) -> void:
	if data.kind == "rock":
		set_process(false)
		return
	queue_redraw()
	if data.kind == "oak" and builder:
		_leaf_t -= delta * builder.speed
		if _leaf_t <= 0.0:
			_leaf_t = randf_range(6.0, 16.0)
			var r: float = art.radius
			builder.particles.emit("leaf", global_position + Vector2(randf_range(-r, r) * 0.7, 0), 1, {"z": art.height * 0.7})


func sway() -> int:
	if builder == null or data.kind == "rock":
		return 0
	# Windböen laufen als Welle über die Karte
	var t: float = builder.anim_time
	var w := sin(t * 0.9 - global_position.x * 0.012 + global_position.y * 0.004)
	var gust := sin(t * 0.23) * 0.5 + 0.5
	return int(round(w * gust * 1.2))


func _draw() -> void:
	var size: Vector2i = art.size
	var foot: Vector2 = art.foot
	var origin := -foot
	var split: int = clampi(int(art.split), 0, size.y)
	var s := sway()
	if split > 0:
		draw_texture_rect_region(art.tex, Rect2(origin + Vector2(s, 0), Vector2(size.x, split)), Rect2(0, 0, size.x, split))
	if split < size.y:
		draw_texture_rect_region(art.tex, Rect2(origin + Vector2(0, split), Vector2(size.x, size.y - split)), Rect2(0, split, size.x, size.y - split))
