extends Node
## Liest config/balance.json beim Start. Alle Balancing-Werte kommen von hier.
## Zugriff mit Pfad: Config.get_value("city/start_money").

const PATH := "res://config/balance.json"

var data: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	var text := FileAccess.get_file_as_string(PATH)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		data = parsed
	else:
		push_error("balance.json fehlt oder ist kaputt: %s" % PATH)
		data = {}


func get_value(path: String, fallback = null):
	var node = data
	for key in path.split("/"):
		if node is Dictionary and node.has(key):
			node = node[key]
		else:
			return fallback
	return node


func num(path: String, fallback: float = 0.0) -> float:
	return float(get_value(path, fallback))


func integer(path: String, fallback: int = 0) -> int:
	return int(get_value(path, fallback))


func building(type: String) -> Dictionary:
	return get_value("buildings/" + type, {})
