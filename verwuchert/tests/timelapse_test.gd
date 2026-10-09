extends SceneTree
## Prüft Phase 2: Verfallsmodell (gleich bei gleichem Seed, wächst mit der Zeit), den Ablauf der Szene
## bis zum Ende, die Zusammenfassung, das Zurückschreiben in die Stadt und den Weg in Phase 3.

var step := 0
var fails := 0
var gs: Node
var tl: Node


func check(cond: bool, msg: String) -> void:
	print(("OK   " if cond else "FAIL ") + msg)
	if not cond:
		fails += 1


func _build_city() -> void:
	gs.new_game(4711)
	var row: int = int(gs.city.h) / 2
	for x in 12:
		var r: Dictionary = gs.add_building("road", x, row)
		gs.finish_building(r)
	var list := [["power_plant", 2, row - 3], ["water_tower", 6, row + 1], ["house", 5, row - 1], ["house", 7, row - 1],
		["house", 9, row + 1], ["shop", 10, row - 1], ["factory", 8, row - 4], ["park", 4, row + 1]]
	for item in list:
		var b: Dictionary = gs.add_building(item[0], item[1], item[2])
		gs.finish_building(b)
	# Eine unfertige Baustelle darf nicht altern
	gs.add_building("house", 14, row - 1)


var started := false


func _initialize() -> void:
	gs = root.get_node("GameState")


## Läuft im ersten Bild, denn die Konfiguration lädt erst nach _initialize.
func _model_checks() -> void:
	_build_city()
	# Modell
	# Erst jetzt laden: die Klasse nutzt Autoloads, die beim Start des Testskripts noch fehlen
	var DM: GDScript = load("res://scripts/timelapse/decay_model.gd")
	var a = DM.new(gs.city)
	var b = DM.new(gs.city)
	check(a.recs.size() == 8, "Acht Gebäude altern, die Baustelle nicht: %d" % a.recs.size())
	check(a.plants.size() == b.plants.size() and a.events.size() == b.events.size(), "Gleicher Seed gibt gleichen Verfall")
	check(str(a.events) == str(b.events), "Gleiche Chronik")
	var rec: Dictionary = a.recs.values()[0]
	var prev := -1.0
	var mono := true
	for y in range(0, 61, 5):
		var f: Dictionary = a.factors(rec, float(y))
		if float(f.collapse) < prev:
			mono = false
		prev = float(f.collapse)
	check(mono, "Einsturz wächst nur")
	check(float(a.factors(rec, 0.0).moss) == 0.0, "Jahr 0 ist makellos")
	check(a.grass_cover(0.0) == 0.0 and a.grass_cover(50.0) >= 0.99, "Gras bedeckt die Straßen am Ende")
	check(a.water_level(0.0) == 0.0 and a.water_level(50.0) > 0.3, "Wasser steigt")
	var p: Dictionary = a.plants[0]
	check(a.plant_kind(p, float(p.year) - 0.1) == "" and a.plant_kind(p, float(p.year) + 0.1) == "sapling", "Pflanze beginnt als Trieb")
	check(a.plant_kind(p, float(p.year) + 100.0) in ["oak", "pine", "bush"], "Pflanze wird groß")
	check(a.events.size() >= 5, "Chronik hat Einträge: %d" % a.events.size())
	var sorted := true
	for i in range(1, a.events.size()):
		if float(a.events[i].year) < float(a.events[i - 1].year):
			sorted = false
	check(sorted, "Chronik ist nach Jahren geordnet")
	check(DM.snow(0.88) > 0.9 and DM.snow(0.3) == 0.0, "Schnee nur im Winter")
	check(DM.season_name(0.1) == "Frühling" and DM.season_name(0.9) == "Winter", "Jahreszeiten")
	change_scene_to_file("res://scenes/phase2_timelapse.tscn")


func _process(_d: float) -> bool:
	if not started:
		started = true
		_model_checks()
		return false
	if current_scene != null and current_scene.scene_file_path.ends_with("phase3_bunker.tscn"):
		check(gs.phase == 3, "Weiter führt zu Phase 3 und die Phase steht auf 3")
		print("FEHLER: %d" % fails)
		return true
	if current_scene == null or not current_scene.has_method("summary_text"):
		return false
	tl = current_scene
	if not tl.loaded:
		return false
	step += 1
	match step:
		1:
			check(tl.world.building_views.size() == 8, "Welt zeigt acht Gebäude: %d" % tl.world.building_views.size())
			check(tl.world.done, "Welt ist fertig gebaut")
			check(tl.camera.zoom.x == 1.0, "Kamera startet nah")
			tl.t = 20.0
		4:
			check(tl.year > 20.0 and tl.year < 25.0, "Jahr läuft mit: %.1f" % tl.year)
			check(tl.hud._year_label.text.begins_with("Jahr 2"), "Anzeige zeigt das Jahr: %s" % tl.hud._year_label.text)
			var any_hidden := false
			for e in tl.world._plants:
				if not e.view.visible:
					any_hidden = true
			check(any_hidden, "Noch nicht gepflanzte Bäume sind unsichtbar")
			tl._on_skip()
			check(tl.skipping, "Überspringen beschleunigt")
			tl.t = tl.duration - 0.05
		8:
			check(tl.finished, "Zeitraffer ist zu Ende")
			check(tl.hud._end.visible, "Zusammenfassung ist sichtbar")
			check(tl.camera.zoom.x < 1.0, "Kamera hat herausgezoomt: %.2f" % tl.camera.zoom.x)
			var c: Dictionary = gs.city
			check(int(c.year) == 50, "Jahr 50 steht in der Stadt")
			var ruined := 0
			for bd in c.buildings:
				if bd.type != "road" and bd.has("ruin"):
					ruined += 1
			check(ruined == 8, "Alle fertigen Gebäude haben Ruinendaten: %d" % ruined)
			check(c.new_trees.size() > 20, "Neue Bäume gespeichert: %d" % c.new_trees.size())
			for id in tl.model.recs:
				var r: Dictionary = tl.model.recs[id]
				print("   ", r.type, " ", r.material, " life=%.1f " % r.life, tl.model.factors(r, 50.0))
			var txt: String = tl.summary_text()
			check(txt.find("Wohnhäuser") >= 0 and txt.find("Bäume") >= 0, "Zusammenfassung nennt Häuser und Bäume")
			print(txt)
			var first_loot: Dictionary = {}
			for bd in c.buildings:
				if bd.type == "factory":
					first_loot = bd
			check(first_loot.ruin.contents.size() <= first_loot.contents.size(), "Fundstücke verderben höchstens")
			check(gs.has_save(), "Stand gespeichert")
			tl._on_continue()
	return false
