class_name TreeView
extends Node2D
## Baum, Busch oder Stein. Die Krone wiegt im Wind, ältere Blätter fallen ab und zu.

var data: Dictionary
var art: Dictionary
var builder: Node
var decor := false
## Bodenpunkt in Feldern. Für Schatten und Lichtkegel.
var ground_pos := Vector2.ZERO
var _leaf_t := 0.0
var _last_sway := 0


func setup(t: Dictionary, city_builder: Node, is_decor := false) -> void:
	data = t
	builder = city_builder
	decor = is_decor
	art = SpriteFactory.tree(t.kind, int(t.seed))
	ground_pos = Vector2(int(t.x) + 0.5 + int(t.get("ox", 0)) / 32.0, int(t.y) + 0.5 + int(t.get("oy", 0)) / 32.0)
	position = Iso.to_screen(ground_pos.x, ground_pos.y).round()
	use_parent_material = true
	_leaf_t = randf_range(2.0, 12.0)
	# Wald im Rand wiegt sich nicht. Er wird einmal gemalt und kostet danach keine Rechenzeit.
	if is_decor:
		set_process(false)


## Wechselt die Art, zum Beispiel vom Trieb zum Busch zum Baum. Der Fuß bleibt am selben Ort.
func regrow(kind: String) -> void:
	if data.kind == kind:
		return
	data.kind = kind
	art = SpriteFactory.tree(kind, int(data.seed))
	queue_redraw()


func tile() -> Vector2i:
	return Vector2i(int(data.x), int(data.y))


func _process(delta: float) -> void:
	if data.kind == "rock":
		set_process(false)
		return
	# Der Wind verschiebt die Krone nur um ganze Pixel, neu gemalt wird nur beim Wechsel
	var s := sway()
	if s != _last_sway:
		_last_sway = s
		queue_redraw()
	if data.kind == "oak" and builder:
		_leaf_t -= delta * builder.speed
		if _leaf_t <= 0.0:
			_leaf_t = randf_range(6.0, 16.0)
			var r: float = art.radius
			builder.particles.emit("leaf", position + Vector2(randf_range(-r, r) * 0.7, 0), 1, {"z": art.height * 0.7})


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
