class_name ShadowPainter
extends Node2D
## Malt alle Schatten deckend schwarz in eine CanvasGroup. Die Gruppe macht sie gemeinsam durchsichtig,
## so werden überlappende Schatten nicht doppelt dunkel. Die Sonne wandert mit der Uhrzeit.

const T := 32

var builder: Node


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if builder == null:
		return
	var sun: Vector2 = DayCycle.sun_vector(builder.hour)
	for v in builder.building_views.values():
		var b: Dictionary = v.data
		if b.state == "queued":
			continue
		var h: float = BuildingTypes.info(b.type).get("height", 20)
		if b.state == "building":
			h *= float(b.progress)
		if h < 2.0:
			continue
		var fp: Rect2 = v.footprint()
		# Grundfläche ohne Vorgarten. Der Schatten fällt vom Dach aus, darum zählt die halbe Höhe.
		var base := Rect2(fp.position + Vector2(3, 2), fp.size - Vector2(6, 8))
		h *= 0.55
		if b.type == "park":
			_blob(Vector2(fp.position.x + 10, fp.end.y - 22), sun * 20.0, 9.0)
			continue
		if b.type == "water_tower":
			var top := Rect2(fp.position.x + 3, fp.end.y - 14, 26, 8)
			_poly_hull([top.position, Vector2(top.end.x, top.position.y), top.end, Vector2(top.position.x, top.end.y)], sun * h)
			for lx in [7.0, 25.0]:
				var foot := Vector2(fp.position.x + lx, fp.end.y - 6)
				draw_line(foot, foot + sun * h * 0.8, Color.BLACK, 1.0)
			continue
		var pts := [base.position, Vector2(base.end.x, base.position.y), base.end, Vector2(base.position.x, base.end.y)]
		_poly_hull(pts, sun * h)
	for tv in builder.tree_views:
		if tv.data.kind == "rock":
			_blob(tv.position + Vector2(1, -1), sun * 3.0, 5.0)
			continue
		var r: float = tv.art.radius
		var hh: float = tv.art.height
		var off: Vector2 = sun * hh * 0.45
		var s: int = tv.sway()
		_blob(tv.position + off + Vector2(s, 0), Vector2.ZERO, r * 0.9)
		draw_line(tv.position, tv.position + off, Color.BLACK, 2.0)
	for lv in builder.lamp_views:
		draw_line(lv.position, lv.position + sun * 16.0, Color.BLACK, 1.0)


func _poly_hull(pts: Array, offset: Vector2) -> void:
	var all := PackedVector2Array()
	for p in pts:
		all.append(p)
		all.append(p + offset)
	var hull := Geometry2D.convex_hull(all)
	if hull.size() >= 3:
		draw_colored_polygon(hull, Color.BLACK)


func _blob(center: Vector2, offset: Vector2, r: float) -> void:
	var c := center + offset
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append((c + Vector2(cos(a) * r, sin(a) * r * 0.55)).round())
	draw_colored_polygon(pts, Color.BLACK)
