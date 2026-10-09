extends SceneTree
## Prüft die Finger-Steuerung mit echten Berührungsereignissen:
## Bauen erst beim Loslassen, Zielpunkt über dem Finger, Straße ziehen, zwei Finger bewegen und zoomen.

var step := 0
var roads_before := 0
var b
var fails := 0
var t1 := Vector2i.ZERO
var t2 := Vector2i.ZERO
var houses := 0
var cam_x := 0.0


func check(cond: bool, msg: String) -> void:
	print(("OK   " if cond else "FAIL ") + msg)
	if not cond:
		fails += 1


func _initialize() -> void:
	root.get_node("GameState").new_game(77)
	change_scene_to_file("res://scenes/phase1_city.tscn")


func touch(i: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = i
	e.position = pos
	e.pressed = pressed
	Input.parse_input_event(e)


func drag(i: int, pos: Vector2, rel: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = i
	e.position = pos
	e.relative = rel
	Input.parse_input_event(e)


## Bildschirmpunkt des Fingers, damit der Zielpunkt (um TOUCH_LIFT höher) auf der Feldmitte liegt.
func finger_for(t: Vector2i) -> Vector2:
	var screen: Vector2 = b.get_viewport().get_canvas_transform() * Iso.center(t)
	return screen + Vector2(0, b.TOUCH_LIFT * b.camera.zoom.x)


func screen_of(t: Vector2i) -> Vector2:
	return b.get_viewport().get_canvas_transform() * Iso.center(t)


func free_tile(near: Vector2i) -> Vector2i:
	for r in range(0, 8):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var t: Vector2i = near + Vector2i(dx, dy)
				if b.can_place("house", t) and b.trees_in(Rect2i(t, Vector2i.ONE)).is_empty():
					return t
	return near


func house_count() -> int:
	var n := 0
	for x in b.city.buildings:
		if x.type == "house":
			n += 1
	return n


func _process(_d: float) -> bool:
	if current_scene != null and current_scene.has_method("map_screen_rect") and not current_scene.loaded:
		return false
	step += 1
	match step:
		3:
			b = current_scene
			b.camera.zoom = Vector2.ONE
			b.camera.position = Iso.to_screen(8, 6)
			b._clamp_camera()
		6:
			b = current_scene
			b.camera.zoom = Vector2.ONE
			b.camera.position = Iso.to_screen(8, 6)
			b._clamp_camera()
			t1 = free_tile(Vector2i(8, 6))
			t2 = free_tile(Vector2i(10, 7))
			if t2 == t1:
				t2 = free_tile(Vector2i(11, 8))
			b.select_tool("house")
			houses = house_count()
			touch(0, finger_for(t1), true)
		8:
			check(b._touch_pending, "Finger unten: Bauen wartet auf das Loslassen")
			check(house_count() == houses, "Beim Aufsetzen wird noch nichts gebaut")
			check(b.hover == t1, "Der Zielpunkt liegt über dem Finger: %s" % str(b.hover))
			drag(0, finger_for(t2), finger_for(t2) - finger_for(t1))
		10:
			check(b.hover == t2, "Der Zielpunkt folgt dem Finger: %s" % str(b.hover))
			check(house_count() == houses, "Beim Ziehen wird nichts gebaut")
			touch(0, finger_for(t2), false)
		12:
			check(house_count() == houses + 1, "Loslassen baut ein Haus")
			check(not b.building_at(t2).is_empty() and b.building_at(t1).is_empty(), "Das Haus steht am Zielpunkt, nicht darunter")
			check(b.tool == "house", "Das Werkzeug bleibt gewählt")
			houses = house_count()
			# Zwei Finger: der erste fängt an zu bauen, der zweite bricht ab und bewegt die Karte
			cam_x = b.camera.position.x
			touch(0, Vector2(300, 150), true)
		14:
			check(b._touch_pending, "Erster Finger wartet")
			touch(1, Vector2(360, 150), true)
		16:
			check(b._gesture and not b._touch_pending, "Zweiter Finger bricht das Bauen ab")
			drag(0, Vector2(260, 150), Vector2(-40, 0))
			drag(1, Vector2(320, 150), Vector2(-40, 0))
		18:
			check(b.camera.position.x > cam_x + 20.0, "Zwei Finger bewegen die Karte: %.0f" % (b.camera.position.x - cam_x))
			touch(0, Vector2(260, 150), false)
			touch(1, Vector2(320, 150), false)
		20:
			check(house_count() == houses, "Nach den zwei Fingern ist nichts gebaut")
			check(not b._gesture, "Die Geste endet, wenn alle Finger oben sind")
			# Auseinanderziehen zoomt
			touch(0, Vector2(300, 150), true)
		22:
			touch(1, Vector2(320, 150), true)
		24:
			drag(0, Vector2(260, 150), Vector2(-40, 0))
			drag(1, Vector2(360, 150), Vector2(40, 0))
		26:
			check(b.camera.zoom.x == 2.0, "Auseinanderziehen zoomt hinein")
			drag(0, Vector2(300, 150), Vector2(40, 0))
			drag(1, Vector2(320, 150), Vector2(-40, 0))
		28:
			check(b.camera.zoom.x == 1.0, "Zusammenziehen zoomt heraus")
			touch(0, Vector2(300, 150), false)
			touch(1, Vector2(320, 150), false)
		30:
			b.set_zoom(1)
			# Ohne Fenster hat das Bild nur 64 x 64 Punkte, darum liegen die Felder nah an der Mitte
			b.camera.position = Iso.to_screen(6, 6)
			b._clamp_camera()
			b.select_tool("road")
			t1 = Vector2i(5, 6)
			t2 = Vector2i(7, 6)
		32:
			touch(0, screen_of(t1), true)
		33:
			drag(0, screen_of(t2), Vector2(100, 0))
		35:
			check(b.road_preview().size() >= 3, "Straße zeigt beim Ziehen eine Vorschau: %d Felder" % b.road_preview().size())
			touch(0, screen_of(t2), false)
		37:
			var n := 0
			for x in range(5, 8):
				if b.roads.has(Vector2i(x, 6)):
					n += 1
			check(n >= 3, "Loslassen baut die Straße: %d Felder" % n)
			b.select_tool("road")
			check(b.tool == "", "Werkzeug nochmal antippen legt es weg")
		38:
			var target := Vector2i.ZERO
			for x in b.city.buildings:
				if x.type == "house":
					target = Vector2i(int(x.x), int(x.y))
			t1 = target
			touch(0, screen_of(target) - Vector2(0, 14), true)
		40:
			touch(0, screen_of(t1) - Vector2(0, 14), false)
		42:
			check(not b.selected.is_empty() and b.selected.type == "house", "Tippen ohne Werkzeug wählt das Haus")
			b.select_tool("road")
			t1 = Vector2i(8, 7)
			roads_before = b.roads.size()
		43:
			touch(0, screen_of(t1), true)
		45:
			touch(0, screen_of(t1), false)
		47:
			check(b.roads.has(t1), "Ein Tipp baut die Straße genau auf das getippte Feld")
			check(b.roads.size() == roads_before + 1, "Genau ein Feld kommt dazu: %d neu" % (b.roads.size() - roads_before))
			print("FEHLER: %d" % fails)
			return true
	return false
