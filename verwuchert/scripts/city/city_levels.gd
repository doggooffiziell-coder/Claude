class_name CityLevels
extends RefCounted
## Stadtstufen: Dorf, Kleinstadt, Stadt, Großstadt. Mehr Bewohner bringen die nächste Stufe,
## Geld als Prämie und neue Gebäude. Die Zahlen stehen in balance.json unter "levels".


static func list() -> Array:
	return Config.get_value("levels", [{"name": "Dorf", "need": 0, "bonus": 0}])


static func count() -> int:
	return list().size()


## Höchste Stufe (ab 1), die mit so vielen Bewohnern erreicht ist.
static func level_for(residents: int) -> int:
	var lvl := 1
	var l := list()
	for i in l.size():
		if residents >= int(l[i].need):
			lvl = i + 1
	return lvl


static func name_of(level: int) -> String:
	var l := list()
	return str(l[clampi(level, 1, l.size()) - 1].name)


static func need_of(level: int) -> int:
	var l := list()
	return int(l[clampi(level, 1, l.size()) - 1].need)


static func bonus_of(level: int) -> int:
	var l := list()
	return int(l[clampi(level, 1, l.size()) - 1].bonus)


## Bewohner für die nächste Stufe, oder -1 auf der höchsten.
static func next_need(level: int) -> int:
	if level >= count():
		return -1
	return need_of(level + 1)


## Welche Gebäude eine Stufe freischaltet.
static func unlocks(level: int) -> Array:
	var out := []
	for t in BuildingTypes.ORDER:
		if BuildingTypes.level_needed(t) == level and level > 1:
			out.append(t)
	return out


static func lock_text(type: String) -> String:
	var lvl := BuildingTypes.level_needed(type)
	return "Ab %s (%d Bewohner)" % [name_of(lvl), need_of(lvl)]
