extends SceneTree
## Prüft das Hauptmenü: Insel, Spielstandanzeige, Seiten, Einstellungen, Abfrage, Löschen und Neustart.

var step := 0
var m
var fails := 0


func check(cond: bool, msg: String) -> void:
	print(("OK   " if cond else "FAIL ") + msg)
	if not cond:
		fails += 1


func _initialize() -> void:
	root.get_node("GameState").delete_save()
	change_scene_to_file("res://scenes/main_menu.tscn")


func _process(_d: float) -> bool:
	if current_scene != null and current_scene.has_method("map_screen_rect") and not current_scene.loaded:
		return false
	step += 1
	var gs = root.get_node("GameState")
	var st = root.get_node("Settings")
	match step:
		5:
			m = current_scene
			var d = m.backdrop.diorama
			check(d.building_views.size() == 13, "Insel hat 13 Gebäude: %d" % d.building_views.size())
			check(d.tree_views.size() == 6 and d.pole_views.size() > 0, "Bäume und Masten stehen: %d, %d" % [d.tree_views.size(), d.pole_views.size()])
			check(m.continue_btn.disabled and m.continue_info.text == "Noch kein Spielstand", "Ohne Spielstand ist Weiterspielen aus")
			var types := {}
			for v in d.building_views.values():
				types[v.data.type] = true
			check(types.has("water_tower") and types.has("factory") and types.has("power_plant"), "Wasserturm, Fabrik und Kraftwerk sind dabei")
			# Spielstand anlegen
			gs.new_game(5)
			gs.save_game()
			m.refresh()
			check(not m.continue_btn.disabled and m.continue_info.text.begins_with("Tag 1"), "Mit Spielstand: %s" % m.continue_info.text)
		8:
			m.show_screen("guide")
			check(m.screens.guide.visible and not m.screens.settings.visible, "Anleitung öffnet")
			m.show_screen("settings")
			check(m.screens.settings.visible and not m.screens.guide.visible, "Einstellungen öffnen")
			m.show_screen("main")
			check(not m.screens.guide.visible and not m.screens.settings.visible, "Zurück zur Hauptseite")
			# Einstellungen wirken und werden gespeichert
			st.shadows = true
			st.toggle("shadows")
			check(not st.shadows, "Schatten aus")
			var saved = JSON.parse_string(FileAccess.get_file_as_string(st.PATH))
			check(saved is Dictionary and saved.shadows == false, "Einstellung steht in der Datei")
			st.toggle("shadows")
			st.start_speed = 1
			st.toggle("start_speed")
			st.toggle("start_speed")
			check(st.start_speed == 3, "Tempo zählt 1, 2, 3: %d" % st.start_speed)
			st.toggle("start_speed")
			check(st.start_speed == 1, "Tempo beginnt wieder bei 1")
			st.start_speed = 2
		12:
			# Mit Spielstand fragt Neues Spiel nach
			m._on_new()
			check(m.screens.confirm.visible, "Neues Spiel fragt nach")
			m.show_screen("main")
			# Löschen braucht zwei Klicks
			m._on_wipe()
			check(gs.has_save(), "Ein Klick löscht noch nicht")
			m._on_wipe()
			check(not gs.has_save() and m.continue_btn.disabled, "Zwei Klicks löschen den Spielstand")
			# Auto und Fußgänger der Insel
			var d = m.backdrop.diorama
			for i in 6:
				d._spawn_car()
			check(d.cars.size() >= 1 and d.traffic.cars.size() == d.cars.size(), "Autos fahren: %d" % d.cars.size())
			for i in 900:
				for c in d.cars.duplicate():
					d._move_car(c, 0.05)
			check(d.cars.size() == 0, "Autos verlassen die Insel wieder")
			for i in 12:
				d._spawn_walker()
			check(d.walkers.size() >= 1, "Fußgänger laufen: %d" % d.walkers.size())
			for i in 900:
				for w in d.walkers.duplicate():
					d._move_walker(w, 0.05)
			check(d.walkers.size() == 0, "Fußgänger kommen an")
		16:
			# Ein Tag auf der Insel: die Nacht kommt
			var d = m.backdrop.diorama
			d.hour = 12.0
			check(DayCycle.night(d.hour) == 0.0, "Mittags ist es hell")
			d.hour = 22.0
			check(DayCycle.night(d.hour) == 1.0, "Um 22 Uhr ist es dunkel")
			m._start_new()
		22:
			check(current_scene.scene_file_path.ends_with("phase1_city.tscn"), "Neues Spiel startet Phase 1")
			check(current_scene.speed_index == 2 and current_scene.speed == 2.0, "Startet mit dem gewählten Tempo: %d" % current_scene.speed_index)
		26:
			st.start_speed = 1
			st.save_settings()
			gs.delete_save()
			print("FEHLER: %d" % fails)
			return true
	return false
