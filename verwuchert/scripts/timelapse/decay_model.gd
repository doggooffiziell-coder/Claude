class_name DecayModel
extends RefCounted
## Der Verfall der Stadt als reine Daten. Alles folgt aus dem Seed und den Gebäuden aus Phase 1,
## darum verwuchert jede Stadt anders und dieselbe Stadt immer gleich.
## Gebäude: Material und Typ bestimmen die Lebensdauer. Pflanzen: wachsen in Gebäuden, auf Straßen und im Gras.
## Jahreszeiten, Wetter und die Chronik der Ereignisse kommen auch von hier.

const SEASONS := ["Frühling", "Sommer", "Herbst", "Winter"]
const SEASON_TINT := [Color(0.96, 1.0, 0.96), Color(1.0, 0.99, 0.92), Color(1.0, 0.86, 0.7), Color(0.84, 0.91, 1.0)]

## Wie stark Material auf Verfall reagiert: Ranken, Moos, Rost, Löcher im Dach.
const MATERIAL_LOOK := {
	"holz": {"vine": 1.0, "moss": 1.0, "rust": 0.0, "holes": 1.0},
	"ziegel": {"vine": 0.9, "moss": 0.8, "rust": 0.0, "holes": 0.8},
	"beton": {"vine": 0.5, "moss": 0.6, "rust": 0.25, "holes": 0.6},
	"stahl": {"vine": 0.5, "moss": 0.4, "rust": 1.0, "holes": 0.9},
	"pflanzen": {"vine": 0.0, "moss": 0.5, "rust": 0.0, "holes": 0.0},
}

var city: Dictionary
var years := 50.0
var seed_value := 0
var recs := {}
var plants: Array[Dictionary] = []
var events: Array[Dictionary] = []
var blackout := 1.0
var abandon_last := 1.0
var grass_full := 26.0
var water_start := 4.0
var water_max := 0.4
var sapling_years := 3.0
var bush_years := 9.0
var _occupied := {}


func _init(city_data: Dictionary) -> void:
	city = city_data
	seed_value = int(city.seed)
	years = Config.num("phase2/years", 50.0)
	grass_full = Config.num("phase2/grass_full_year", 26.0)
	water_start = Config.num("phase2/water_start_year", 4.0)
	water_max = Config.num("phase2/water_max", 0.4)
	sapling_years = Config.num("phase2/sapling_years", 3.0)
	bush_years = Config.num("phase2/bush_years", 9.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 2024
	var bo: Array = Config.get_value("phase2/blackout_years", [0.7, 1.6])
	blackout = rng.randf_range(float(bo[0]), float(bo[1]))
	_make_recs(rng)
	_make_plants(rng)
	_make_events()


# Gebäude

func _make_recs(rng: RandomNumberGenerator) -> void:
	var ab: Array = Config.get_value("phase2/abandon_years", [0.3, 1.1])
	var spread := Config.num("phase2/life_spread", 0.3)
	for b in city.buildings:
		# Unfertige Baustellen verschwinden, nur fertige Gebäude altern
		if str(b.get("state", "done")) != "done":
			continue
		if b.type == "road":
			_occupied[Vector2i(int(b.x), int(b.y))] = -2
			continue
		for yy in int(b.h):
			for xx in int(b.w):
				_occupied[Vector2i(int(b.x) + xx, int(b.y) + yy)] = int(b.id)
		var r := RandomNumberGenerator.new()
		r.seed = hash([seed_value, int(b.id), "decay"])
		var mat := str(b.get("material", "ziegel"))
		var life := Config.num("phase2/life_years/" + mat, 40.0) * Config.num("phase2/type_life/" + str(b.type), 1.0)
		if b.type == "park":
			life = 70.0
		life *= 1.0 + r.randf_range(-spread, spread)
		life *= 0.85 + 0.3 * float(b.get("condition", 100)) / 100.0
		var look: Dictionary = MATERIAL_LOOK.get(mat, MATERIAL_LOOK.ziegel)
		recs[int(b.id)] = {
			"id": int(b.id), "type": b.type, "material": mat, "life": life,
			"abandon": r.randf_range(float(ab[0]), float(ab[1])),
			"vine": float(look.vine) * r.randf_range(0.8, 1.15), "moss": float(look.moss),
			"rust": float(look.rust), "holes": float(look.holes),
			"seed": r.randf() * 90.0 + 3.0,
		}
		if b.type == "house":
			abandon_last = maxf(abandon_last, float(recs[int(b.id)].abandon))


## Zustand eines Gebäudes im Jahr y. Alle Werte von 0 bis 1, age bis 1.3.
func factors(rec: Dictionary, year: float) -> Dictionary:
	var age := maxf(0.0, year / float(rec.life))
	return {
		"age": minf(age, 1.3),
		"moss": clampf(smoothstep(0.04, 0.55, age) * float(rec.moss), 0.0, 1.0),
		"vine": clampf(smoothstep(0.12, 0.85, age) * float(rec.vine), 0.0, 1.0),
		"rust": clampf(smoothstep(0.08, 0.65, age) * float(rec.rust), 0.0, 1.0),
		"holes": clampf(smoothstep(0.5, 0.95, age) * float(rec.holes), 0.0, 1.0),
		"collapse": smoothstep(0.9, 1.3, age) if rec.type != "park" else 0.0,
	}


func hole_year(rec: Dictionary) -> float:
	return float(rec.life) * 0.62


func collapse_year(rec: Dictionary) -> float:
	return float(rec.life) * 1.08


## Brennen die Lichter noch? Mit dem Kraftwerk fällt der Strom aus, Häuser leeren sich vorher.
func powered(year: float) -> bool:
	return year < blackout


func occupied(rec: Dictionary, year: float) -> bool:
	return year < float(rec.abandon)


# Pflanzen

func _make_plants(rng: RandomNumberGenerator) -> void:
	var inside: Array = Config.get_value("phase2/plants_inside", [1, 3])
	var kinds := ["oak", "oak", "oak", "pine", "bush"]
	for id in recs:
		var rec: Dictionary = recs[id]
		if rec.type == "park":
			continue
		var b := _building(int(id))
		var n := rng.randi_range(int(inside[0]), int(inside[1]))
		if int(b.w) * int(b.h) >= 4:
			n += 1
		for i in n:
			var tx := int(b.x) + rng.randi_range(0, int(b.w) - 1)
			var ty := int(b.y) + rng.randi_range(0, int(b.h) - 1)
			plants.append({"x": tx, "y": ty, "ox": rng.randi_range(-8, 8), "oy": rng.randi_range(-6, 6),
				"seed": rng.randi() % 9999, "final": kinds[rng.randi() % kinds.size()],
				"year": hole_year(rec) * rng.randf_range(0.75, 1.1) + float(i), "inside": int(id)})
	var total := Config.integer("phase2/plants_total", 150)
	var w: int = city.w
	var h: int = city.h
	var pond := Terrain.ponds(seed_value, w, h, Config.integer("city/pond_count", 1))
	var placed := 0
	var guard := 0
	while placed < total and guard < total * 40:
		guard += 1
		var tx := rng.randi_range(0, w - 1)
		var ty := rng.randi_range(0, h - 1)
		var t := Vector2i(tx, ty)
		if pond[ty * w + tx] != 0:
			continue
		var occ: int = int(_occupied.get(t, -1))
		var on_road := occ == -2
		if occ >= 0:
			continue
		var year := years * pow(rng.randf(), 0.85) * 0.96
		if on_road:
			# Asphalt hält länger. Erst wenn das Gras durch ist, bricht der erste Baum durch.
			if rng.randf() > 0.3:
				continue
			year = maxf(year, years * 0.3)
		plants.append({"x": tx, "y": ty, "ox": rng.randi_range(-10, 10), "oy": rng.randi_range(-10, 10),
			"seed": rng.randi() % 9999, "final": "bush" if (on_road or rng.randf() < 0.25) else kinds[rng.randi() % 4],
			"year": year, "inside": -1})
		placed += 1
	plants.sort_custom(func(a, b): return float(a.year) < float(b.year))


## Art der Pflanze im Jahr y. Leer, wenn sie noch nicht da ist.
func plant_kind(p: Dictionary, year: float) -> String:
	var age := year - float(p.year)
	if age < 0.0:
		return ""
	if age < sapling_years:
		return "sapling"
	if p.final == "bush" or age < sapling_years + bush_years:
		return "bush"
	return str(p.final)


# Boden und Wetter

## Wie viel Gras die Straßen bedeckt, 0 bis 1.
func grass_cover(year: float) -> float:
	return pow(clampf(year / grass_full, 0.0, 1.0), 1.3)


## Wasserstand in Höheneinheiten des Geländes. Regen füllt die Senken.
func water_level(year: float) -> float:
	return water_max * smoothstep(water_start, years * 0.9, year)


## Jahreszeit aus der Phase eines Jahres von 0 bis 1. Beginnt im Frühsommer.
static func season_phase(t: float, cycle: float) -> float:
	return fposmod(0.3 + t / cycle, 1.0)


static func season_name(phase: float) -> String:
	return SEASONS[clampi(int(phase * 4.0), 0, 3)]


static func season_tint(phase: float) -> Color:
	var f := phase * 4.0 - 0.5
	var i := int(floorf(f))
	var k := f - float(i)
	k = k * k * (3.0 - 2.0 * k)
	var a: Color = SEASON_TINT[posmod(i, 4)]
	var b: Color = SEASON_TINT[posmod(i + 1, 4)]
	return a.lerp(b, k)


static func snow(phase: float) -> float:
	return smoothstep(0.72, 0.8, phase) * (1.0 - smoothstep(0.95, 1.0, phase))


static func rain(phase: float) -> float:
	var spring := smoothstep(0.0, 0.05, phase) * (1.0 - smoothstep(0.14, 0.22, phase))
	var autumn := smoothstep(0.58, 0.62, phase) * (1.0 - smoothstep(0.68, 0.72, phase)) * 0.7
	return maxf(spring, autumn)


static func leaves(phase: float) -> float:
	return smoothstep(0.5, 0.56, phase) * (1.0 - smoothstep(0.72, 0.78, phase))


# Chronik

func _building(id: int) -> Dictionary:
	for b in city.buildings:
		if int(b.id) == id:
			return b
	return {}


func label(b: Dictionary) -> String:
	var n := str(b.get("name", ""))
	if n != "":
		return n
	if b.type == "house":
		return "Haus " + Names.family(seed_value, int(b.id))
	return BuildingTypes.display_name(b.type)


func _event(year: float, text: String) -> void:
	events.append({"year": year, "text": text})


func _make_events() -> void:
	_event(abandon_last, "Die letzten Bewohner ziehen aus. Die Häuser stehen leer.")
	_event(blackout, "Das Kraftwerk steht still. Die Lichter gehen aus.")
	_event(water_start + 3.0, "Regen sammelt sich in den Senken. Die Teiche wachsen.")
	_event(grass_full * pow(0.2, 1.0 / 1.3), "Gras bricht durch den Asphalt.")
	_event(grass_full * pow(0.7, 1.0 / 1.3), "Die Straßen sind kaum noch zu sehen.")
	var seen_hole := {}
	var seen_fall := {}
	var by_year: Array = recs.values()
	by_year.sort_custom(func(a, b): return float(a.life) < float(b.life))
	for rec in by_year:
		var b := _building(int(rec.id))
		if rec.type == "park":
			continue
		if not seen_hole.has(rec.type) and hole_year(rec) < years:
			seen_hole[rec.type] = true
			_event(hole_year(rec), "%s: Das Dach bricht ein." % label(b))
		if not seen_fall.has(rec.type) and collapse_year(rec) < years:
			seen_fall[rec.type] = true
			_event(collapse_year(rec), "%s stürzt ein." % label(b))
	for p in plants:
		if p.inside >= 0:
			var rec: Dictionary = recs[int(p.inside)]
			var b := _building(int(p.inside))
			_event(float(p.year) + sapling_years, "Mitten in %s wächst ein Baum." % label(b))
			break
	_event(years - 1.5, "Die Stadt ist ein Wald mit Mauern geworden.")
	events = events.filter(func(e): return float(e.year) <= years)
	events.sort_custom(func(a, b): return float(a.year) < float(b.year))


# Ergebnis

## Zählt, was im Jahr y noch steht. Schlüssel: Typ, Werte: stehend, dachlos, eingestürzt.
func summary(year: float) -> Dictionary:
	var out := {}
	for id in recs:
		var rec: Dictionary = recs[id]
		if rec.type == "park":
			continue
		var f := factors(rec, year)
		var key := "stehend"
		if float(f.collapse) > 0.6:
			key = "eingestürzt"
		elif float(f.holes) > 0.35:
			key = "dachlos"
		if not out.has(rec.type):
			out[rec.type] = {"stehend": 0, "dachlos": 0, "eingestürzt": 0}
		out[rec.type][key] = int(out[rec.type][key]) + 1
	return out


## Schreibt den Zustand der Ruinen in die Stadt, damit Phase 3 ihn nutzt.
## Inhalte verderben je nach Art, eingestürzte Gebäude verschütten einen Teil.
func write_back() -> void:
	var keep: Dictionary = Config.get_value("phase2/loot_keep", {})
	for b in city.buildings:
		if not recs.has(int(b.id)):
			continue
		var rec: Dictionary = recs[int(b.id)]
		var f := factors(rec, years)
		var stage := "stehend"
		if float(f.collapse) > 0.6:
			stage = "eingestürzt"
		elif float(f.holes) > 0.35:
			stage = "dachlos"
		var rest := {}
		for item in b.contents:
			var k := float(keep.get(item, 0.7)) * (1.0 - 0.4 * float(f.collapse))
			if item == "holz" and str(b.material) != "holz":
				k = 0.9
			var n := int(round(float(b.contents[item]) * k))
			if n > 0:
				rest[item] = n
		b.ruin = {"stage": stage, "contents": rest, "collapse": snappedf(float(f.collapse), 0.01),
			"holes": snappedf(float(f.holes), 0.01), "vine": snappedf(float(f.vine), 0.01),
			"condition": int(round(100.0 * (1.0 - clampf(float(f.age) / 1.2, 0.0, 1.0))))}
	var trees: Array = []
	for p in plants:
		var kind := plant_kind(p, years)
		if kind != "":
			trees.append({"x": p.x, "y": p.y, "ox": p.ox, "oy": p.oy, "seed": p.seed, "kind": kind, "inside": p.inside})
	city.new_trees = trees
	city.year = int(years)
