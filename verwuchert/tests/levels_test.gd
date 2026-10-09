extends SceneTree
## Prüft Stadtstufen, gesperrte Gebäude und die vier neuen Gebäude: Wohnblock, Klinik, Lagerhaus, Solarpark.

var step := 0
var fails := 0
var b: Node
var gs: Node
var started := false
var BT
var CL
var row := 8
var income_factory := 0
var income_house := 0


func check(cond: bool, msg: String) -> void:
	print(("OK   " if cond else "FAIL ") + msg)
	if not cond:
		fails += 1


func _process(_d: float) -> bool:
	# Die Konfiguration lädt erst nach _initialize
	if not started:
		started = true
		gs = root.get_node("GameState")
		gs.new_game(555)
		change_scene_to_file("res://scenes/phase1_city.tscn")
		return false
	if current_scene == null or not current_scene.has_method("map_screen_rect") or not current_scene.loaded:
		return false
	step += 1
	match step:
		3:
			b = current_scene
			BT = load("res://scripts/city/building_types.gd")
			CL = load("res://scripts/city/city_levels.gd")
			row = b.entry_row
			check(int(gs.city.level) == 1, "Start als Dorf")
			check(CL.name_of(1) == "Dorf" and CL.name_of(4) == "Großstadt", "Stufen heißen Dorf bis Großstadt")
			check(not b.is_unlocked("apartment") and not b.is_unlocked("clinic"), "Wohnblock und Klinik sind gesperrt")
			b.select_tool("apartment")
			check(b.tool == "", "Gesperrtes Werkzeug lässt sich nicht wählen")
			check(not b.place("apartment", Vector2i(10, row + 1), true), "Gesperrtes Gebäude lässt sich nicht bauen")
			check(CL.lock_text("clinic").begins_with("Ab Stadt"), "Sperrtext nennt die Stufe: %s" % CL.lock_text("clinic"))
			check(CL.level_for(0) == 1 and CL.level_for(CL.need_of(2)) == 2 and CL.level_for(99999) == 4, "Stufe folgt den Bewohnern")
			# Straße und Versorger bauen
			b.tool = "road"
			b.place_road_path(b._l_path(Vector2i(3, row), Vector2i(16, row)))
			b.tool = ""
			for item in [["power_plant", 3, row - 2], ["water_tower", 6, row + 1]]:
				b.tool = item[0]
				check(b.place(item[0], Vector2i(item[1], item[2]), true), "%s gebaut" % item[0])
			b.tool = ""
			b.set_speed(3)
		6:
			for i in 600:
				b._tick(0.1)
			b._update_status()
			check(b.power_cap == 36 and b.water_cap == 24, "Kraftwerk 36 und Wasserturm 24 Plätze: %d, %d" % [b.power_cap, b.water_cap])
			# Stufe 2 durch Bewohner
			var money: int = gs.city.money
			b.residents = CL.need_of(2)
			b._check_level()
			check(int(gs.city.level) == 2, "Stufe 2 erreicht")
			check(int(gs.city.money) == money + CL.bonus_of(2), "Prämie wurde ausgezahlt: %d" % CL.bonus_of(2))
			check(b.is_unlocked("apartment") and b.is_unlocked("solar") and b.is_unlocked("warehouse") and not b.is_unlocked("clinic"), "Stufe 2 schaltet Wohnblock, Lager und Solarpark frei")
			b.select_tool("apartment")
			check(b.tool == "apartment", "Wohnblock ist jetzt wählbar")
			b.tool = ""
			gs.city.money = 100000
			b.tool = "apartment"
			check(b.place("apartment", Vector2i(10, row + 1), true), "Wohnblock 2x1 gebaut")
			b.tool = "house"
			check(b.place("house", Vector2i(8, row - 1), true), "Haus gebaut")
			b.tool = "solar"
			check(b.place("solar", Vector2i(13, row - 1), true), "Solarpark gebaut")
			b.tool = "factory"
			check(b.place("factory", Vector2i(11, row - 2), true), "Fabrik gebaut")
			b.tool = ""
		9:
			for i in 1200:
				b._tick(0.1)
			b._update_status()
			check(b.power_cap == 46, "Solarpark erhöht die Leistung auf 46: %d" % b.power_cap)
			var apt: Dictionary = b.building_at(Vector2i(10, row + 1))
			var av = b.building_views[int(apt.id)]
			check(av.status.get("occupied", false), "Wohnblock ist bewohnt")
			check(b.residents >= 12, "Wohnblock bringt 12 Bewohner: %d" % b.residents)
			check(b.water_load >= 4 and b.power_load >= 4, "Wohnblock braucht mehr Strom und Wasser: %d/%d" % [b.power_load, b.water_load])
			check(apt.has("people") and apt.people.size() == 12, "Wohnblock hat 12 Namen")
			check(int(av.status.income) >= 200, "Wohnblock zahlt Steuern: %d" % int(av.status.income))
			var fac: Dictionary = b.building_at(Vector2i(11, row - 2))
			income_factory = int(b.building_views[int(fac.id)].status.income)
			var house: Dictionary = b.building_at(Vector2i(8, row - 1))
			income_house = int(b.building_views[int(house.id)].status.income)
			check(income_factory == 450, "Fabrik ohne Lager: 450, ist %d" % income_factory)
			b.tool = "warehouse"
			check(b.place("warehouse", Vector2i(13, row + 1), true), "Lagerhaus gebaut")
			b.tool = ""
			# Stufe 3 für die Klinik
			b.residents = CL.need_of(3)
			b._check_level()
			check(int(gs.city.level) == 3 and b.is_unlocked("clinic"), "Stufe 3 schaltet die Klinik frei")
			b.tool = "clinic"
			check(b.place("clinic", Vector2i(8, row + 1), true), "Klinik 2x2 gebaut")
			b.tool = ""
		12:
			for i in 1500:
				b._tick(0.1)
			b._update_status()
			var fac: Dictionary = b.building_at(Vector2i(11, row - 2))
			var fi: int = int(b.building_views[int(fac.id)].status.income)
			check(fi > income_factory, "Lagerhaus bringt der Fabrik mehr: %d statt %d" % [fi, income_factory])
			var house: Dictionary = b.building_at(Vector2i(8, row - 1))
			var hv = b.building_views[int(house.id)]
			check(hv.status.get("healthy", false) and int(hv.status.income) > income_house, "Klinik bringt dem Haus mehr: %d statt %d" % [int(hv.status.income), income_house])
			# Speichern behält die Stufe
			check(gs.save_game(), "Gespeichert")
			gs.city = {}
			check(gs.load_game() and int(gs.city.level) == 3, "Stufe 3 steht im Spielstand")
			print("FEHLER: %d" % fails)
			return true
	return false
