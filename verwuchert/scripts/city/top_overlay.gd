class_name TopOverlay
extends Node2D
## Über allem: Geist-Vorschau beim Bauen, Warnblasen, Auswahl.

const T := 32

var builder: Node


func _process(_delta: float) -> void:
	queue_redraw()


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
	var art: Dictionary = SpriteFactory.building(tool, builder.ghost_variant, builder.ghost_material())
	var size := BuildingTypes.size_of(tool)
	var pos := Vector2(builder.hover.x * T, (builder.hover.y + size.y) * T - art.size.y)
	var valid: bool = builder.can_place(tool, builder.hover)
	var col := Color(1, 1, 1, 0.62) if valid else Color(1.0, 0.45, 0.4, 0.55)
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
		var fp: Rect2 = v.footprint()
		var top_y: float = fp.end.y - v.art.size.y + int(v.art.get("top", 0))
		var w := needs.size() * 10 + 2
		var x := roundf(fp.get_center().x - w * 0.5)
		var bob := roundf(sin(t * 3.0 + float(b.id)) * 1.0)
		var y := top_y - 12 + bob
		# Blase blinkt sanft
		if fposmod(t + float(b.id) * 0.3, 2.4) > 2.0:
			continue
		draw_rect(Rect2(x - 1, y - 1, w + 2, 13), Pal.BLACK)
		draw_rect(Rect2(x, y, w, 11), Pal.BONE)
		draw_rect(Rect2(x, y + 10, w, 1), Pal.STONE_L)
		draw_rect(Rect2(x + w * 0.5 - 1, y + 11, 3, 1), Pal.BLACK)
		draw_rect(Rect2(x + w * 0.5, y + 11, 1, 2), Pal.BLACK)
		draw_rect(Rect2(x + w * 0.5 - 1, y + 10, 2, 1), Pal.BONE)
		for i in needs.size():
			draw_texture(IconArt.get_icon(needs[i]), Vector2(x + 1 + i * 10, y + 1))


func _draw_selection() -> void:
	var sel: Dictionary = builder.selected
	if sel.is_empty():
		return
	var r := Rect2(int(sel.x) * T, int(sel.y) * T, int(sel.w) * T, int(sel.h) * T)
	var t: float = builder.anim_time
	var pulse := 1.0 if fposmod(t, 1.0) < 0.6 else 0.0
	var col := Pal.a(Pal.YELLOW, 0.6 + 0.4 * pulse)
	var l := 7.0
	draw_rect(Rect2(r.position, Vector2(l, 1)), col)
	draw_rect(Rect2(r.position, Vector2(1, l)), col)
	draw_rect(Rect2(Vector2(r.end.x - l, r.position.y), Vector2(l, 1)), col)
	draw_rect(Rect2(Vector2(r.end.x - 1, r.position.y), Vector2(1, l)), col)
	draw_rect(Rect2(Vector2(r.position.x, r.end.y - 1), Vector2(l, 1)), col)
	draw_rect(Rect2(Vector2(r.position.x, r.end.y - l), Vector2(1, l)), col)
	draw_rect(Rect2(r.end - Vector2(l, 1), Vector2(l, 1)), col)
	draw_rect(Rect2(r.end - Vector2(1, l), Vector2(1, l)), col)
