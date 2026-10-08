extends Node
## Einstellungen des Spielers. Liegen als JSON in user://verwuchert_settings.json.
## Jeder Wert wirkt sofort, auch im Menü.

const PATH := "user://verwuchert_settings.json"

var shadows := true
var particles := true
var fullscreen := false
var start_speed := 1


func _ready() -> void:
	load_settings()
	apply()


func load_settings() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not (parsed is Dictionary):
		return
	shadows = bool(parsed.get("shadows", shadows))
	particles = bool(parsed.get("particles", particles))
	fullscreen = bool(parsed.get("fullscreen", fullscreen))
	start_speed = clampi(int(parsed.get("start_speed", start_speed)), 1, 3)


func save_settings() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"shadows": shadows, "particles": particles,
		"fullscreen": fullscreen, "start_speed": start_speed,
	}, "\t"))


func can_fullscreen() -> bool:
	return not OS.has_feature("web") and DisplayServer.get_name() != "headless"


func apply() -> void:
	if not can_fullscreen():
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


## Ändert einen Schalter oder zählt eine Stufe weiter, speichert und wendet an.
func toggle(key: String) -> void:
	match key:
		"shadows": shadows = not shadows
		"particles": particles = not particles
		"fullscreen": fullscreen = not fullscreen
		"start_speed": start_speed = start_speed % 3 + 1
	save_settings()
	apply()
