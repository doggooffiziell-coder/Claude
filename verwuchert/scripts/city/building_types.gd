class_name BuildingTypes
extends RefCounted
## Feste Eigenschaften der sieben Gebäudetypen. Kosten und Zeiten stehen in balance.json.

const ORDER: Array[String] = ["road", "house", "shop", "factory", "park", "water_tower", "power_plant"]

const INFO := {
	"road": {
		"name": "Straße", "size": Vector2i(1, 1), "height": 0,
		"desc": "Verbindet Gebäude. Ziehen baut eine ganze Strecke.",
		"needs": "",
	},
	"house": {
		"name": "Wohnhaus", "size": Vector2i(1, 1), "height": 26,
		"desc": "4 Bewohner zahlen Steuern. Parks in der Nähe bringen mehr.",
		"needs": "Straße, Strom, Wasser",
	},
	"shop": {
		"name": "Laden", "size": Vector2i(1, 1), "height": 24,
		"desc": "Verdient an bewohnten Häusern in der Nähe. Lagert Konserven.",
		"needs": "Straße, Strom, Kunden",
	},
	"factory": {
		"name": "Fabrik", "size": Vector2i(2, 2), "height": 40,
		"desc": "Bringt viel Geld, verschmutzt aber die Häuser daneben.",
		"needs": "Straße, Strom",
	},
	"park": {
		"name": "Park", "size": Vector2i(1, 1), "height": 18,
		"desc": "Macht Häuser in der Nähe beliebter. Später wächst hier alles zuerst.",
		"needs": "",
	},
	"water_tower": {
		"name": "Wasserturm", "size": Vector2i(1, 1), "height": 88,
		"desc": "Versorgt Häuser über die Straßen mit Wasser.",
		"needs": "Straße daneben",
	},
	"power_plant": {
		"name": "Kraftwerk", "size": Vector2i(2, 2), "height": 56,
		"desc": "Versorgt Gebäude über die Straßen mit Strom. Kostet Unterhalt.",
		"needs": "Straße daneben",
	},
}

const MATERIAL_NAMES := {
	"asphalt": "Asphalt", "holz": "Holz", "ziegel": "Ziegel",
	"beton": "Beton", "stahl": "Stahl", "pflanzen": "Pflanzen",
}

const ITEM_NAMES := {
	"steine": "Steine", "stoff": "Stoff", "holz": "Holz", "konserven": "Konserven",
	"medizin": "Medizin", "wasser": "Wasserflaschen", "metall": "Metall",
	"werkzeug": "Werkzeug", "kabel": "Kabel", "samen": "Samen", "rohre": "Rohre",
	"batterie": "Batterien",
}


static func info(type: String) -> Dictionary:
	return INFO.get(type, {})


static func display_name(type: String) -> String:
	return info(type).get("name", type)


static func size_of(type: String) -> Vector2i:
	return info(type).get("size", Vector2i.ONE)


static func cost(type: String) -> int:
	return int(Config.building(type).get("cost", 0))


static func build_time(type: String) -> float:
	return float(Config.building(type).get("build_time", 1.0))


static func uses_crew(type: String) -> bool:
	return bool(Config.building(type).get("uses_crew", true))


## Wählt das Material nach den Gewichten aus balance.json.
static func roll_material(type: String, rng: RandomNumberGenerator) -> String:
	var weights: Dictionary = Config.get_value("materials/" + type, {})
	var total := 0.0
	for k in weights:
		total += float(weights[k])
	var pick := rng.randf() * total
	for k in weights:
		pick -= float(weights[k])
		if pick <= 0.0:
			return k
	return weights.keys()[0] if not weights.is_empty() else "beton"


## Würfelt den Inhalt. Er bestimmt, was in Phase 3 in der Ruine liegt.
static func roll_contents(type: String, rng: RandomNumberGenerator) -> Dictionary:
	var out := {}
	var table: Dictionary = Config.get_value("loot/" + type, {})
	for item in table:
		var r: Array = table[item]
		var n := rng.randi_range(int(r[0]), int(r[1]))
		if n > 0:
			out[item] = n
	return out
