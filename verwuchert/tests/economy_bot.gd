extends SceneTree
## Spielt Phase 1 mit einem einfachen Bot, um das Tempo der Wirtschaft zu messen.
## Er baut Straßen, Versorger und Wohnungen, sobald das Geld reicht, und meldet, wann welche
## Stadtstufe erreicht ist. Das ist ein Messgerät fürs Balancing, kein Gewinnspiel.
## Aufruf: godot --headless --path verwuchert -s res://tests/economy_bot.gd -- --minutes=30

var b: Node
var step := 0
var t := 0.0
var next_check := 0.0
var levels_seen := 1
var minutes := 30.0
# Erst zur Laufzeit laden: die Klassen nutzen Autoloads, die beim Start des Skripts noch fehlen
var BT
var CL


var started := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--minutes="):
			minutes = float(a.trim_prefix("--minutes="))


func _spot(type: String) -> Vector2i:
	var size: Vector2i = BT.size_of(type)
	var w: int = b.city.w
	var h: int = b.city.h
	for y in range(h):
		for x in range(w):
			var t0 := Vector2i(x, y)
			if not b.can_place(type, t0):
				continue
			var fake := {"x": x, "y": y, "w": size.x, "h": size.y}
			if b.touches_road(fake):
				return t0
	return Vector2i(-1, -1)


func _build(type: String) -> bool:
	var spot := _spot(type)
	if spot.x < 0:
		if int(b.city.money) > 4000 and b.roads_open == 0:
			_roads()
		return false
	b.tool = type
	b._reroll_ghost()
	var ok: bool = b.place(type, spot, true)
	b.tool = ""
	return ok


var _road_i := 0


## Baut das nächste Stück Straßennetz: erst die Hauptstraße, dann Querstraßen.
func _roads() -> void:
	var row: int = b.entry_row
	var paths := [[Vector2i(3, row), Vector2i(22, row)]]
	for x in [7, 13, 19]:
		paths.append([Vector2i(x, row), Vector2i(x, 2)])
		paths.append([Vector2i(x, row), Vector2i(x, 14)])
	if _road_i >= paths.size():
		return
	var p: Array = paths[_road_i]
	_road_i += 1
	b.tool = "road"
	b.place_road_path(b._l_path(p[0], p[1]))
	b.tool = ""


func _count(type: String) -> int:
	var n := 0
	for x in b.city.buildings:
		if x.type == type:
			n += 1
	return n


func _decide() -> void:
	var money: int = b.city.money
	var lvl: int = b.city.level
	if _road_i == 0:
		_roads()
		return
	# Erst wenn die Bautrupps frei sind, wird weiter bestellt. Sonst zählt die Versorgung noch nicht.
	if b.queue_length() > 0 or b.crews_busy() >= 2:
		return
	var supply_pending := false
	for x in b.city.buildings:
		if x.state != "done" and x.type in ["power_plant", "water_tower", "solar"]:
			supply_pending = true
	# Leere Wohnungen zeigen, was fehlt: Strom oder Wasser. Daran richtet sich der Bot aus.
	var need_bolt := 0
	var need_drop := 0
	var empty_homes := 0
	for v in b.building_views.values():
		if v.data.type in ["house", "apartment"] and v.data.state == "done" and not v.status.get("occupied", false):
			empty_homes += 1
			if "bolt" in v.status.get("needs", []):
				need_bolt += 1
			if "drop" in v.status.get("needs", []):
				need_drop += 1
	if empty_homes >= 2 and not supply_pending:
		if need_bolt >= need_drop and money >= BT.cost("power_plant") and _build("power_plant"):
			return
		if need_drop > need_bolt and money >= BT.cost("water_tower") and _build("water_tower"):
			return
	if empty_homes >= 4:
		return
	var spare_p: int = b.power_cap - b.power_load
	var spare_w: int = b.water_cap - b.water_load
	var want_apartments := lvl >= 2
	# Versorgung zuerst
	if not supply_pending and (_count("power_plant") + _count("solar") == 0 or spare_p < (14 if want_apartments else 6)):
		if money >= BT.cost("power_plant") and _build("power_plant"):
			return
		if lvl >= 2 and money >= BT.cost("solar") and _build("solar"):
			return
	if not supply_pending and (_count("water_tower") == 0 or spare_w < (12 if want_apartments else 5)):
		if money >= BT.cost("water_tower") and _build("water_tower"):
			return
	if lvl >= 2 and _count("warehouse") < 1 and _count("factory") >= 1 and money >= BT.cost("warehouse"):
		if _build("warehouse"):
			return
	if lvl >= 3 and _count("clinic") < 2 and money >= BT.cost("clinic"):
		if _build("clinic"):
			return
	if _count("factory") < 2 and money >= BT.cost("factory") and _count("house") >= 6:
		if _build("factory"):
			return
	if _count("shop") < _count("house") / 4 and money >= BT.cost("shop"):
		if _build("shop"):
			return
	if _count("park") < _count("house") / 6 and money >= BT.cost("park"):
		if _build("park"):
			return
	if want_apartments and money >= BT.cost("apartment"):
		if _build("apartment"):
			return
	if money >= BT.cost("house"):
		_build("house")


func _process(_d: float) -> bool:
	# Die Konfiguration lädt erst nach _initialize, darum startet das Spiel erst jetzt
	if not started:
		started = true
		root.get_node("GameState").new_game(2024)
		change_scene_to_file("res://scenes/phase1_city.tscn")
		return false
	if current_scene == null or not current_scene.has_method("map_screen_rect") or not current_scene.loaded:
		return false
	step += 1
	if step == 3:
		BT = load("res://scripts/city/building_types.gd")
		CL = load("res://scripts/city/city_levels.gd")
		b = current_scene
		b.set_speed(3)
		return false
	if b == null:
		return false
	for i in 20:
		b._tick(0.1)
		t += 0.1
		if t >= next_check:
			next_check = t + 4.0
			b._update_status()
			_decide()
			# Bautrupps sind knapp: nur so viel bestellen, wie die Warteschlange vertragen kann
		var lvl: int = b.city.level
		if lvl > levels_seen:
			levels_seen = lvl
			print("Stufe %d (%s) nach %.1f Minuten, Bewohner %d, Geld %d" % [lvl, CL.name_of(lvl), t / 60.0, b.residents, int(b.city.money)])
	if t >= minutes * 60.0:
		b._update_status()
		var counts := {}
		for x in b.city.buildings:
			counts[x.type] = int(counts.get(x.type, 0)) + 1
		print(counts, " power ", b.power_load, "/", b.power_cap, " water ", b.water_load, "/", b.water_cap, " occupied ", b.occupied_houses)
		print("Ende nach %.0f Minuten: Stufe %d, Bewohner %d, Geld %d, Einnahmen pro Zahltag %d, Gebäude %d" % [t / 60.0, b.city.level, b.residents, int(b.city.money), b.income_per_payday(), b.city.buildings.size()])
		return true
	return false
