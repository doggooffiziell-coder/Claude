extends Node
## Hält die Stadt als reine Daten und reicht sie von Phase zu Phase weiter.
## Speichert und lädt alles als JSON in user://verwuchert_save.json.

const SAVE_PATH := "user://verwuchert_save.json"
const SAVE_FORMAT := 1

const PHASE_SCENES := {
	1: "res://scenes/phase1_city.tscn",
	2: "res://scenes/phase2_timelapse.tscn",
	3: "res://scenes/phase3_bunker.tscn",
}

var phase := 1
var city: Dictionary = {}

## Befehlszeilen-Schalter für Tests: --demo baut eine Beispielstadt, --shot=pfad macht ein Bild.
var user_args: Dictionary = {}


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		user_args[parts[0]] = parts[1] if parts.size() > 1 else "1"


func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


func new_game(seed_value: int = -1) -> void:
	var rng := RandomNumberGenerator.new()
	if seed_value < 0:
		rng.randomize()
		seed_value = rng.randi() % 1000000
	rng.seed = seed_value
	var w := Config.integer("city/grid_w", 24)
	var h := Config.integer("city/grid_h", 16)
	phase = 1
	city = {
		"seed": seed_value,
		"w": w,
		"h": h,
		"money": Config.integer("city/start_money", 1500),
		"time": 0.0,
		"hour": Config.num("city/start_hour", 7.5),
		"day": 1,
		"payday_timer": 0.0,
		"next_id": 1,
		"buildings": [],
		"trees": [],
	}
	_place_nature(rng)


## Bäume, Büsche und Steine. Sie stehen im Weg und wachsen in Phase 2 weiter.
func _place_nature(rng: RandomNumberGenerator) -> void:
	var w: int = city.w
	var h: int = city.h
	var pond := Terrain.ponds(city.seed, w, h, Config.integer("city/pond_count", 1))
	var hs := Terrain.heights(city.seed, w, h)
	var density := Config.num("city/tree_density", 0.1)
	var rocks := Config.num("city/rock_density", 0.02)
	for y in h:
		for x in w:
			var i := y * w + x
			if pond[i] != 0:
				continue
			# Bäume stehen lieber in Gruppen und am Rand
			var edge := 1.0 if (x < 2 or y < 2 or x >= w - 2 or y >= h - 2) else 0.0
			var chance := density * (0.6 + (1.0 - hs[i]) * 0.9 + edge * 0.8)
			var roll := rng.randf()
			if roll < chance:
				var kind := "oak" if rng.randf() < 0.62 else "pine"
				if rng.randf() < 0.25:
					kind = "bush"
				city.trees.append({"x": x, "y": y, "kind": kind, "seed": rng.randi() % 9999,
					"ox": rng.randi_range(-5, 5), "oy": rng.randi_range(-4, 4)})
			elif roll < chance + rocks:
				city.trees.append({"x": x, "y": y, "kind": "rock", "seed": rng.randi() % 9999,
					"ox": rng.randi_range(-6, 6), "oy": rng.randi_range(-5, 5)})


## variant und material kommen von der Vorschau, damit das Haus so aussieht wie gezeigt.
func add_building(type: String, x: int, y: int, variant: int = -1, material: String = "") -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([city.seed, x, y, city.next_id])
	var size := BuildingTypes.size_of(type)
	var b := {
		"id": int(city.next_id),
		"type": type,
		"x": x, "y": y, "w": size.x, "h": size.y,
		"material": material if material != "" else BuildingTypes.roll_material(type, rng),
		"variant": variant if variant >= 0 else rng.randi() % 10000,
		"state": "queued",
		"progress": 0.0,
		"condition": 100,
		"contents": {},
		"built_day": 0,
	}
	city.next_id = int(city.next_id) + 1
	city.buildings.append(b)
	return b


## Fertige Gebäude bekommen ihren Inhalt. Er liegt in Phase 3 in den Ruinen.
func finish_building(b: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(b.variant) * 31 + int(b.id)
	b.state = "done"
	b.progress = 1.0
	b.contents = BuildingTypes.roll_contents(b.type, rng)
	b.built_day = int(city.day)


func remove_building(b: Dictionary) -> void:
	city.buildings.erase(b)


func building_by_id(id: int) -> Dictionary:
	for b in city.buildings:
		if int(b.id) == id:
			return b
	return {}


# Speichern und Laden

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Liest nur die Eckdaten des Spielstands, ohne ihn zu laden. Für das Hauptmenü.
func peek_save() -> Dictionary:
	if not has_save():
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not (parsed is Dictionary) or not parsed.has("city"):
		return {}
	var c: Dictionary = parsed.city
	var families := 0
	var list: Array = c.get("buildings", [])
	for b in list:
		if b.has("family"):
			families += 1
	return {"phase": int(parsed.get("phase", 1)), "day": int(c.get("day", 1)), "money": int(c.get("money", 0)),
		"buildings": list.size(), "families": families}


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)


func save_game() -> bool:
	var data := {
		"format": SAVE_FORMAT,
		"version": version(),
		"phase": phase,
		"city": city,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Speichern fehlgeschlagen: %s" % FileAccess.get_open_error())
		return false
	f.store_string(JSON.stringify(data, "\t"))
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not (parsed is Dictionary) or not parsed.has("city"):
		return false
	phase = int(parsed.get("phase", 1))
	city = parsed.city
	_fix_types()
	return true


## JSON kennt nur Kommazahlen. Ganze Zahlen werden hier wieder ganze Zahlen.
func _fix_types() -> void:
	for key in ["seed", "w", "h", "money", "day", "next_id"]:
		city[key] = int(city.get(key, 0))
	for b in city.buildings:
		for key in ["id", "x", "y", "w", "h", "variant", "condition", "built_day"]:
			b[key] = int(b.get(key, 0))
		var fixed := {}
		for item in b.contents:
			fixed[item] = int(b.contents[item])
		b.contents = fixed
	for t in city.trees:
		for key in ["x", "y", "seed", "ox", "oy"]:
			t[key] = int(t.get(key, 0))


func go_to_phase(n: int) -> void:
	phase = n
	get_tree().change_scene_to_file(PHASE_SCENES[n])


func continue_game() -> void:
	if load_game():
		go_to_phase(phase)
