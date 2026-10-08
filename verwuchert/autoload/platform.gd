extends Node
## Erkennt Handy und Touch, passt das Bildformat an und hält das Spiel an, wenn die Seite es verlangt.
## Auf dem Handy bekommt das Spiel ein breiteres Bild ohne schwarze Ränder. Die kleinste Fläche ist
## 620 x 270 Punkte, die Vergrößerung ist immer eine ganze Zahl, also bleiben die Pixel scharf.

## Kleinste sichtbare Fläche in Spielpunkten. Das Handy hat ein breiteres, aber kürzeres Bild.
const PHONE_MIN := Vector2i(620, 270)
const DESKTOP_MIN := Vector2i(640, 360)
const AUTOSAVE_PHONE := 20.0

## Läuft auf einem Handy im Browser, oder wurde mit --phone erzwungen.
var phone := false
## Es wurde schon ein Finger benutzt.
var touch := false

var _poll := 0.0
var _was_paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		phone = bool(JavaScriptBridge.eval("window.matchMedia('(pointer: coarse)').matches && window.matchMedia('(hover: none)').matches", true))
	if GameState.user_args.has("phone"):
		phone = true
	touch = phone
	_apply_scale()
	get_window().size_changed.connect(_apply_scale)


## Wählt die größte ganze Vergrößerung, bei der die kleinste Fläche noch passt, und gibt dem Spiel
## genau so viele Punkte, wie auf das Fenster passen. Godot rundet bei breiterem Bild nicht selbst
## auf ganze Zahlen, darum rechnen wir. So bleiben alle Pixel gleich groß und nichts hat schwarze Ränder.
func _apply_scale() -> void:
	var w := get_window()
	var ws := Vector2(w.size)
	var need := Vector2(PHONE_MIN if phone else DESKTOP_MIN)
	var s := maxi(1, int(floorf(minf(ws.x / need.x, ws.y / need.y))))
	var logical := Vector2i(int(ws.x) / s, int(ws.y) / s)
	if w.content_scale_size != logical:
		w.content_scale_size = logical
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not touch:
		touch = true


## Die Seite setzt window.vwPaused, zum Beispiel im Hochformat oder wenn der Tab verborgen ist.
func _process(delta: float) -> void:
	_poll -= delta
	if _poll > 0.0:
		return
	_poll = 0.25
	if not OS.has_feature("web"):
		return
	var paused := bool(JavaScriptBridge.eval("window.vwPaused === true", true))
	if paused == _was_paused:
		return
	_was_paused = paused
	get_tree().paused = paused
	if paused:
		save_now()


## Sichert eine laufende Stadt sofort.
func save_now() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("map_screen_rect") and not GameState.city.is_empty():
		GameState.save_game()


func autosave_seconds() -> float:
	return AUTOSAVE_PHONE if phone else Config.num("city/autosave_seconds", 60.0)


## Größe der sichtbaren Fläche in Spielpunkten.
func view_size() -> Vector2:
	return get_viewport().get_visible_rect().size
