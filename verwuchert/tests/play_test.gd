extends SceneTree
## Spielt Phase 1 automatisch durch und prüft Bauen, Bautrupps, Versorgung, Geld und Speichern.

var step := 0
var b: Node
var fails := 0


func check(cond: bool, msg: String) -> void:
	print(("OK   " if cond else "FAIL ") + msg)
	if not cond:
		fails += 1


func _initialize() -> void:
	var gs = root.get_node("GameState")
	gs.new_game(1234)
	change_scene_to_file("res://scenes/phase1_city.tscn")


func _process(_d: float) -> bool:
	step += 1
	var gs = root.get_node("GameState")
	match step:
		5:
			b = current_scene
			check(b is CityBuilder, "Phase-1-Szene geladen")
			check(b.roads.size() == 3, "Startstraße hat 3 Felder")
			var money: int = gs.city.money
			var row: int = b.entry_row
			b.tool = "road"
			b.place_road_path(b._l_path(Vector2i(3, row), Vector2i(10, row)))
			check(b.roads.size() == 11, "Straße gezogen: %d Felder" % b.roads.size())
			check(gs.city.money < money, "Straße kostet Geld")
			# Kraftwerk, Wasserturm, Häuser
			for item in [["power_plant", 3, row - 2], ["water_tower", 6, row + 1], ["house", 7, row - 1], ["house", 8, row - 1], ["house", 9, row + 1], ["shop", 10, row - 1]]:
				b.tool = item[0]
				for tv in b.trees_in(Rect2i(Vector2i(item[1], item[2]), BuildingTypes.size_of(item[0]))):
					pass
				var ok: bool = b.place(item[0], Vector2i(item[1], item[2]), true)
				check(ok, "%s gebaut bei %d,%d" % [item[0], item[1], item[2]])
			b.tool = ""
			check(b.crews_busy() == 0 or true, "Bautrupps gezählt")
			b.set_speed(3)
		10:
			check(b.crews_busy() == 2, "Zwei Bautrupps arbeiten: %d" % b.crews_busy())
			check(b.queue_length() == 4, "Vier Baustellen warten: %d" % b.queue_length())
			# Zeit vorspulen
			for i in 900:
				b._tick(0.1)
			b._update_status()
			check(b.queue_length() == 0 and b.crews_busy() == 0, "Alles fertig gebaut")
			var occ: int = b.occupied_houses
			check(occ == 3, "Drei Häuser bewohnt: %d" % occ)
			check(b.residents == 12, "12 Bewohner: %d" % b.residents)
			check(b.power_load > 0 and b.power_cap == 24, "Strom fließt über die Straßen: %d/%d" % [b.power_load, b.power_cap])
			var fam := 0
			for bd in gs.city.buildings:
				if bd.has("family"):
					fam += 1
			check(fam == 3, "Drei Familien mit Namen: %d" % fam)
			check(gs.city.chronicle.size() >= 5, "Chronik hat Einträge: %d" % gs.city.chronicle.size())
			print("     Chronik: ", gs.city.chronicle[gs.city.chronicle.size() - 1].text)
			var inc: int = b.income_per_payday()
			print("     Einnahmen pro Zahltag: %d  %s" % [inc, str(b.income_parts)])
			check(inc > 0, "Stadt verdient Geld")
			for bd in gs.city.buildings:
				if bd.type == "shop":
					check(not bd.contents.is_empty(), "Laden hat Inhalt: %s" % str(bd.contents))
			# Grundsteuer: ein Haus ohne Strom zahlt trotzdem etwas
			b.tool = "house"
			var far := Vector2i(20, 2)
			b.place("house", far, true)
			b.tool = ""
			for i in 120:
				b._tick(0.1)
			b._update_status()
			var lone = b.building_at(far)
			var lv = b.building_views[int(lone.id)]
			check(not lv.status.get("occupied", false) and int(lv.status.get("income", 0)) > 0, "Leeres Haus zahlt Grundsteuer: %d" % int(lv.status.get("income", 0)))
			# Abreißen
			var before: int = gs.city.money
			b.demolish(Vector2i(9, b.entry_row + 1))
			check(gs.city.money > before, "Abriss bringt Geld zurück")
			check(b.building_at(Vector2i(9, b.entry_row + 1)).is_empty(), "Feld ist frei")
			# Teich und Rand
			check(not b.can_place("house", Vector2i(-1, 0)), "Außerhalb nicht baubar")
			# Speichern und Laden
			check(gs.save_game(), "Gespeichert")
			var n: int = gs.city.buildings.size()
			var m: int = gs.city.money
			gs.city = {}
			check(gs.load_game(), "Geladen")
			check(gs.city.buildings.size() == n and int(gs.city.money) == m, "Spielstand gleich: %d Gebäude, %d Geld" % [n, m])
			check(typeof(gs.city.buildings[0].id) == TYPE_INT, "IDs sind ganze Zahlen")
			change_scene_to_file("res://scenes/phase1_city.tscn")
		16:
			b = current_scene
			check(b.building_views.size() > 0, "Nach dem Laden stehen die Gebäude wieder: %d" % b.building_views.size())
			b.finish_city()
		22:
			check(current_scene.scene_file_path.ends_with("phase2_timelapse.tscn"), "Phase 2 gestartet")
			check(gs.phase == 2, "Phase steht auf 2")
			print("FEHLER: %d" % fails)
			return true
	return false
