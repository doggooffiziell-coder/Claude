class_name TopOverlay
extends Node2D
## Über allem: Geist-Vorschau beim Bauen, Warnblasen, Auswahl.

var builder: Node
var _was := false
var _bubbles := false
var _check := 0.0


## Nur zeichnen, wenn es etwas zu zeigen gibt: Vorschau, Auswahl oder eine Blase.
func _process(delta: float) -> void:
	if builder == null:
		return
	_check -= delta
	if _check <= 0.0:
		_check = 0.25
		_bubbles = false
		for v in builder.building_views.values():
			if v.data.state == "done" and not v.status.get("needs", []).is_empty():
				_bubbles = true
				break
	var active: bool = builder.tool != "" or not builder.selected.is_empty() or _bubbles
	if active or _was:
		queue_redraw()
	_was = active


func _draw() -> void:
	if builder == null:
		return
	_draw_bubbles()
	_draw_selection()
	_draw_ghost()


func _draw_ghost() -> void:
	var tool: String = builder.tool
	if tool == "" or tool == "road" or tool == "demolish" or not builder.hover_inside():
		return
	var h: Vector2i = builder.hover
	var facing: String = builder.facing_for(tool, h)
	var art: Dictionary = SpriteFactory.building(tool, builder.ghost_variant, builder.ghost_material(), facing)
	var size := BuildingTypes.size_of(tool)
	var pos: Vector2 = Iso.bottom(h.x, h.y, size.x, size.y) - art.anchor
	var valid: bool = builder.can_place(tool, h)
	var col := Color(1, 1, 1, 0.65) if valid else Color(1.0, 0.45, 0.4, 0.55)
	draw_texture(art.tex, pos, col)


## Blasen über Gebäuden, denen etwas fehlt: Straße, Strom, Wasser, Kunden.
func _draw_bubbles() -> void:
	var t: float = builder.anim_time
	for v in builder.building_views.values():
		var b: Dictionary = v.data
		if b.state != "done":
			continue
		var needs: Array = v.status.get("needs", [])
		if needs.is_empty():
			continue
		if fposmod(t + float(b.id) * 0.3, 2.4) > 2.0:
			continue
		var top: Vector2 = v.top_point()
		var w := needs.size() * 10 + 2
		var x := roundf(top.x - w * 0.5)
		var bob := roundf(sin(t * 3.0 + float(b.id)) * 1.0)
		var y := top.y - 15 + bob
		draw_rect(Rect2(x - 1, y - 1, w + 2, 13), Pal.BLACK)
		draw_rect(Rect2(x, y, w, 11), Pal.BONE)
		draw_rect(Rect2(x, y + 10, w, 1), Pal.STONE_L)
		var mid := roundf(top.x)
		draw_rect(Rect2(mid - 1, y + 11, 3, 1), Pal.BLACK)
		draw_rect(Rect2(mid, y + 11, 1, 2), Pal.BLACK)
		draw_rect(Rect2(mid - 1, y + 10, 2, 1), Pal.BONE)
		for i in needs.size():
			draw_texture(IconArt.get_icon(needs[i]), Vector2(x + 1 + i * 10, y + 1))


## Auswahl: pulsierende Raute um die Grundfläche.
func _draw_selection() -> void:
	var sel: Dictionary = builder.selected
	if sel.is_empty():
		return
	var pts := Iso.diamond(float(sel.x), float(sel.y), float(sel.w), float(sel.h))
	var on := fposmod(float(builder.anim_time), 1.0) < 0.6
	var col := Pal.a(Pal.YELLOW, 1.0 if on else 0.55)
	for i in 4:
		var a: Vector2 = pts[i].round()
		var b: Vector2 = pts[(i + 1) % 4].round()
		draw_line(a, b, col)
	# Ecken etwas dicker
	for p in pts:
		draw_rect(Rect2((p as Vector2).round() - Vector2(1, 1), Vector2(3, 3)), col)
