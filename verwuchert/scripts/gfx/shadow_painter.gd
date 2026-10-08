class_name ShadowPainter
extends Node2D
## Malt alle Schatten deckend schwarz in eine CanvasGroup. Die Gruppe macht sie gemeinsam durchsichtig,
## so werden überlappende Schatten nicht doppelt dunkel. Gerechnet wird im Bodenraum,
## Iso.GROUND kippt alles zur Raute. Die Sonne wandert mit der Uhrzeit.

const T := 32

var builder: Node


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if builder == null:
		return
	draw_set_transform_matrix(Iso.GROUND)
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
		var x := float(b.x) * T
		var y := float(b.y) * T
		var w := float(b.w) * T
		var hh := float(b.h) * T
		match b.type:
			"park":
				_blob(Vector2(x + 0.32 * T, y + 0.3 * T), sun * 14.0, 8.0)
			"water_tower":
				_capsule(Vector2(x + 16, y + 16), 10.0, sun * h * 0.9, 14.0)
			_:
				var inset := 0.18 * T if b.type in ["house", "shop"] else 0.12 * T
				var base := Rect2(x + inset, y + inset, w - inset * 2.0, hh - inset * 2.0)
				_hull([base.position, Vector2(base.end.x, base.position.y), base.end, Vector2(base.position.x, base.end.y)], sun * h * 0.9)
				if b.type == "factory":
					_blob(Vector2(x + 1.45 * T, y + 0.3 * T), sun * 84.0 * 0.9, 3.0)
				if b.type == "power_plant":
					_blob(Vector2(x + 0.62 * T, y + 0.6 * T), sun * 78.0 * 0.6, 12.0)
	for tv in builder.tree_views:
		var g: Vector2 = tv.ground_pos * T
		if tv.data.kind == "rock":
			_blob(g, sun * 3.0, 5.0)
			continue
		var r: float = tv.art.radius
		var hgt: float = tv.art.height
		var off: Vector2 = sun * hgt * 0.65
		_blob(g + off, Vector2.ZERO, r * 0.85)
		draw_line(g, g + off, Color.BLACK, 2.0)
	for pv in builder.pole_views:
		var gp: Vector2 = pv.ground_pos * T
		draw_line(gp, gp + sun * 20.0, Color.BLACK, 1.0)
	for c in builder.traffic.cars:
		_blob(c.gpos * T, sun * 3.0, 5.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _hull(pts: Array, offset: Vector2) -> void:
	var all := PackedVector2Array()
	for p in pts:
		all.append(p)
		all.append(p + offset)
	var hull := Geometry2D.convex_hull(all)
	if hull.size() >= 3:
		draw_colored_polygon(hull, Color.BLACK)


## Schatten eines Turms: vom Fuß bis zum breiteren Kopf.
func _capsule(a: Vector2, ra: float, off: Vector2, rb: float) -> void:
	var pts := []
	for i in 12:
		var d := Vector2(cos(TAU * i / 12.0), sin(TAU * i / 12.0))
		pts.append(a + d * ra)
		pts.append(a + off + d * rb)
	_hull(pts, Vector2.ZERO)


func _blob(center: Vector2, offset: Vector2, r: float) -> void:
	var c := center + offset
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, Color.BLACK)
