extends SceneTree
## Prüft echte Maus-Eingaben: Werkzeug wählen, auf die Karte klicken, Straße ziehen, Gebäude anklicken.

var step := 0
var b
var fails := 0


func check(cond: bool, msg: String) -> void:
	print(("OK   " if cond else "FAIL ") + msg)
	if not cond:
		fails += 1


func _initialize() -> void:
	root.get_node("GameState").new_game(77)
	change_scene_to_file("res://scenes/phase1_city.tscn")


func screen_of(t: Vector2i) -> Vector2:
	var wp := Vector2(t.x * 32 + 16, t.y * 32 + 16)
	return b.get_viewport().get_canvas_transform() * wp


func mouse(pos: Vector2, button := 0, pressed := false) -> void:
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	Input.parse_input_event(m)
	if button != 0:
		var e := InputEventMouseButton.new()
		e.button_index = button
		e.pressed = pressed
		e.position = pos
		e.global_position = pos
		Input.parse_input_event(e)


func _process(_d: float) -> bool:
	step += 1
	var gs = root.get_node("GameState")
	match step:
		5:
			b = current_scene
			b.camera.position = Vector2(8 * 32, 8 * 32)
			# Werkzeug über die Leiste wählen
			var hud = b.get_node("HUD/Root")
			(hud._tool_buttons["road"] as Button).emit_signal("pressed")
			check(b.tool == "road", "Straßenwerkzeug gewählt")
		8:
			var row: int = b.entry_row
			for t in b.trees_in(Rect2i(3, row, 6, 1)):
				pass
			mouse(screen_of(Vector2i(3, row)), MOUSE_BUTTON_LEFT, true)
		10:
			mouse(screen_of(Vector2i(8, b.entry_row)))
		12:
			mouse(screen_of(Vector2i(8, b.entry_row)), MOUSE_BUTTON_LEFT, false)
		14:
			check(b.roads.size() >= 9, "Straße per Maus gezogen: %d Felder" % b.roads.size())
			b.select_tool("house")
			mouse(screen_of(Vector2i(5, b.entry_row - 1)), MOUSE_BUTTON_LEFT, true)
		16:
			mouse(screen_of(Vector2i(5, b.entry_row - 1)), MOUSE_BUTTON_LEFT, false)
			check(not b.building_at(Vector2i(5, b.entry_row - 1)).is_empty(), "Haus per Klick gebaut")
			# Rechtsklick bricht ab
			mouse(screen_of(Vector2i(5, b.entry_row + 2)), MOUSE_BUTTON_RIGHT, true)
		18:
			mouse(screen_of(Vector2i(5, b.entry_row + 2)), MOUSE_BUTTON_RIGHT, false)
		20:
			check(b.tool == "", "Rechtsklick legt das Werkzeug weg")
			mouse(screen_of(Vector2i(5, b.entry_row - 1)), MOUSE_BUTTON_LEFT, true)
		22:
			mouse(screen_of(Vector2i(5, b.entry_row - 1)), MOUSE_BUTTON_LEFT, false)
		24:
			check(not b.selected.is_empty() and b.selected.type == "house", "Klick wählt das Haus aus")
			var hud = b.get_node("HUD/Root")
			check(hud._info_panel.visible, "Infotafel ist sichtbar")
			mouse(Vector2(300, 150), MOUSE_BUTTON_LEFT, true)
		26:
			var m := InputEventMouseMotion.new()
			m.position = Vector2(260, 130)
			m.relative = Vector2(-40, -20)
			Input.parse_input_event(m)
		28:
			mouse(Vector2(260, 130), MOUSE_BUTTON_LEFT, false)
			check(b.camera.position.x > 8 * 32 + 10, "Ziehen ohne Werkzeug bewegt die Karte")
			print("FEHLER: %d" % fails)
			return true
	return false
