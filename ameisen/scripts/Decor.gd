extends Node2D
## Zeichnet den Inhalt der Kammern: Futter, Eier, Larven, Tote und Abfall.

var main
var _t := 0.0

const FOOD_COLORS := [Color(0.86, 0.22, 0.16), Color(0.95, 0.55, 0.15), Color(0.95, 0.8, 0.25)]
const SLOTS := [Vector2(0, 2), Vector2(2, 2), Vector2(1, 1)]


func tick(dt: float) -> void:
	_t -= dt
	if main.colony.decor_dirty and _t <= 0.0:
		_t = 0.25
		main.colony.decor_dirty = false
		queue_redraw()


func _sorted_cells(ch: int) -> Array:
	var cells: Array = Array(main.world.chamber_cells[ch])
	cells.sort_custom(func(a, b): return a > b)   # unten zuerst, wie ein Haufen
	return cells


func _draw() -> void:
	if main == null:
		return
	var W := World.W
	var T := World.T
	var c = main.colony
	# Futter in den Kornkammern
	var gran := _sorted_cells(World.CH_GRANARY)
	var food_items := int(c.food)
	var k := 0
	for cell in gran:
		var base := Vector2((cell % W) * T, (cell / W) * T)
		for s in SLOTS:
			if k >= food_items:
				break
			draw_rect(Rect2(base + s, Vector2(1, 1)), FOOD_COLORS[World.hash2(cell, k) % 3])
			k += 1
		if k >= food_items:
			break
	# Abfall, der noch in der Kornkammer wartet
	var tw := int(c.trash_waiting)
	for n in mini(tw, gran.size()):
		var cell2: int = gran[gran.size() - 1 - n]
		draw_rect(Rect2((cell2 % W) * T + 1, (cell2 / W) * T + 2, 1, 1), Color(0.45, 0.35, 0.22))
	# Eier und Larven
	for b in c.brood:
		var cell3: int = b[4]
		var o := World.hash2(cell3, int(b[1] * 10.0) % 3) % 2
		var p := Vector2((cell3 % W) * T + o, (cell3 / W) * T + 1)
		if b[0] == 0:
			draw_rect(Rect2(p, Vector2(1, 2)), Color(0.97, 0.95, 0.88))
		else:
			var col := Color(0.96, 0.88, 0.68) if b[2] > 0.3 else Color(0.85, 0.82, 0.75)
			draw_rect(Rect2(p, Vector2(2, 2)), col)
			draw_rect(Rect2(p, Vector2(1, 1)), col.darkened(0.2))
	# Friedhof
	var cem := _sorted_cells(World.CH_CEMETERY)
	var dead: int = c.buried
	var cap := cem.size() * 2
	for n in mini(dead, cap):
		var cell4: int = cem[n % maxi(cem.size(), 1)]
		var p2 := Vector2((cell4 % W) * T, (cell4 / W) * T + (2 if n < cem.size() else 0))
		_dead_ant(p2)
	# Müllkammer
	var tr := _sorted_cells(World.CH_TRASH)
	for n in mini(c.trash_stored, tr.size() * 3):
		var cell5: int = tr[n % maxi(tr.size(), 1)]
		var s2: Vector2 = SLOTS[(n / maxi(tr.size(), 1)) % 3]
		var tc := Color(0.45, 0.33, 0.2) if World.hash2(cell5, n) % 2 == 0 else Color(0.55, 0.5, 0.42)
		draw_rect(Rect2((cell5 % W) * T + s2.x, (cell5 / W) * T + s2.y, 1, 1), tc)
	# Tote, die noch in den Gängen liegen
	for cell6 in c.corpses:
		_dead_ant(Vector2((cell6 % W) * T, (cell6 / W) * T + 1))
	for sc in c.surface_corpses:
		var a := clampf(1.0 - sc[1] / 30.0, 0.0, 1.0)
		var p3: Vector2 = sc[0] - Vector2(1.5, 0.0)
		p3.y -= main.world.surface_offset(int(p3.x / T))
		draw_rect(Rect2(p3, Vector2(3, 1)), Color(0.15, 0.1, 0.08, a))


func _dead_ant(p: Vector2) -> void:
	var c := Color(0.16, 0.11, 0.09)
	draw_rect(Rect2(p + Vector2(0, 1), Vector2(3, 1)), c)
	draw_rect(Rect2(p + Vector2(0, 0), Vector2(1, 1)), c.lightened(0.15))
	draw_rect(Rect2(p + Vector2(2, 0), Vector2(1, 1)), c.lightened(0.15))
