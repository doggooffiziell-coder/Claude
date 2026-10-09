extends Node2D
## Leuchtende Fenster, Lampen und Warnlichter eines Gebäudes. Wird addiert und nicht abgedunkelt.

static var _add_mat: CanvasItemMaterial

var view: Node2D
var _acc := 0.0
var _was_drawn := false


func setup(owner_view: Node2D) -> void:
	view = owner_view
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_add_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = _add_mat
	use_parent_material = false


## Fensterschein und Warnlicht ändern sich langsam. Fünfzehn Bilder pro Sekunde reichen,
## und am Tag ohne Warnlicht gibt es nichts zu zeichnen.
func _process(delta: float) -> void:
	_acc += delta
	if _acc < 0.066 or view == null or view.builder == null:
		return
	_acc = 0.0
	var active: bool = view.data.state == "done" and (float(view.builder.night) > 0.01 or not view.art.get("blink", []).is_empty())
	if active or _was_drawn:
		queue_redraw()
	_was_drawn = active


func _lit() -> float:
	if view.data.state != "done":
		return 0.0
	var st: Dictionary = view.status
	match view.data.type:
		"house", "apartment":
			return 1.0 if st.get("occupied", false) else 0.0
		"shop", "factory", "clinic", "warehouse":
			return 1.0 if st.get("active", false) else 0.25
		_:
			return 1.0


func _draw() -> void:
	if view == null or view.builder == null:
		return
	var night: float = view.builder.night
	var art: Dictionary = view.art
	var origin: Vector2 = -art.anchor
	var lit := _lit() * night
	if lit > 0.01:
		# Leichtes Flackern hinter Fenstern
		var t: float = view.builder.anim_time
		var f := 0.88 + 0.12 * sin(t * 1.7 + float(view.data.id) * 1.3)
		draw_texture(art.glow, origin, Color(f * lit, f * lit, f * lit, 1.0))
	# Rote Warnlichter blinken immer
	var blink: Array = art.get("blink", [])
	if view.data.state == "done" and not blink.is_empty():
		var t2: float = view.builder.anim_time + float(view.data.id) * 0.37
		var on := fposmod(t2, 1.6) < 0.35
		if on:
			for p in blink:
				var bp: Vector2 = origin + p
				draw_rect(Rect2(bp, Vector2.ONE), Pal.a(Pal.BRICK_L, 1.0))
				var halo := 0.25 + night * 0.35
				draw_rect(Rect2(bp + Vector2(-1, 0), Vector2(3, 1)), Pal.a(Pal.BRICK, halo))
				draw_rect(Rect2(bp + Vector2(0, -1), Vector2(1, 3)), Pal.a(Pal.BRICK, halo))
