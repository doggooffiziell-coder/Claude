class_name WireLayer
extends Node2D
## Stromleitungen zwischen benachbarten Masten, leicht durchhängend.

var builder: Node
var _version := -1


## Die Leitungen ändern sich nur, wenn Masten dazukommen oder fehlen.
func _process(_delta: float) -> void:
	if builder != null and int(builder.pole_version) != _version:
		_version = int(builder.pole_version)
		queue_redraw()


func _draw() -> void:
	if builder == null:
		return
	var poles: Array = builder.pole_views
	for i in poles.size():
		var a = poles[i]
		for j in range(i + 1, poles.size()):
			var b = poles[j]
			var d: Vector2 = b.ground_pos - a.ground_pos
			# Nur Nachbarn entlang der Straße verbinden
			if d.length() > 2.6 or (absf(d.x) > 0.95 and absf(d.y) > 0.95):
				continue
			_wire(a.top(), b.top())


func _wire(a: Vector2, b: Vector2) -> void:
	var steps := maxi(4, int(a.distance_to(b) / 3.0))
	var sag := a.distance_to(b) * 0.08
	var prev := a
	for k in range(1, steps + 1):
		var f := float(k) / steps
		var p := a.lerp(b, f) + Vector2(0, sin(f * PI) * sag)
		draw_line(prev.round(), p.round(), Pal.a(Pal.NIGHT, 0.85), 1.0)
		prev = p
