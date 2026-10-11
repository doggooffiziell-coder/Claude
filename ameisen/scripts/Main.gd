extends Node2D
## Hauptszene: verbindet alle Teile, gibt den Takt vor und speichert den Spielstand.

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1
const AUTOSAVE := 30.0

@onready var world: World = $World
@onready var colony = $Colony
@onready var ants = $Ants
@onready var phero = $Pheromones
@onready var events = $EventManager
@onready var cam = $Camera2D
@onready var hud = $HUD
@onready var day_night: CanvasModulate = $DayNight

var _save_t := 0.0
var paused := false
var speed := 1
var _dead_t := -1.0


func _ready() -> void:
	world.setup(self)
	phero.setup(self)
	colony.setup(self)
	ants.setup(self)
	events.setup(self)
	hud.setup(self)
	cam.tapped.connect(_on_tap)
	if not load_game():
		new_game()


func new_game() -> void:
	world.new_world(randi() % 1000000 + 1)
	phero.clear()
	colony.new_colony()
	ants.clear()
	events.reset()
	ants.spawn(World.ENT, 54, Ant.R_QUEEN)
	var cells: PackedInt32Array = world.chamber_cells[World.CH_QUEEN]
	for k in 5:
		var c := cells[randi() % cells.size()]
		ants.spawn(c % World.W, c / World.W, Ant.R_WORKER, randf_range(0.0, 60.0))
	_dead_t = -1.0
	hud.banner("EINE NEUE KOLONIE", 3.0)


func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	if not paused:
		# bei 2x und 4x läuft die Simulation mehrmals pro Frame
		for k in speed:
			events.tick(dt)
			colony.tick(dt)
			ants.tick(dt)
			world.tick(dt)
			phero.tick(dt)
	world.sky.tick(dt)
	world.decor.tick(dt)
	hud.tick(dt)
	ants.render()
	# Kolonie ausgestorben: nach kurzer Pause neu beginnen
	if ants.count == 0:
		if _dead_t < 0.0:
			_dead_t = 0.0
			hud.banner("DIE KOLONIE IST AUSGESTORBEN", 6.0)
		_dead_t += dt
		if _dead_t > 6.0:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
			new_game()
	_save_t += dt
	if _save_t > AUTOSAVE:
		_save_t = 0.0
		save_game()


func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()
	# im Hintergrund nichts zeichnen, das spart Akku
	if what == NOTIFICATION_APPLICATION_PAUSED:
		get_tree().paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		get_tree().paused = false


# ---------------------------------------------------------------- Antippen

func _on_tap(wp: Vector2, sp: Vector2) -> void:
	if hud.handle_tap(sp):
		return
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(12)
	var x := floori(wp.x / World.T)
	var y := floori(wp.y / World.T)
	if not world.in_grid(x, y):
		hud.hide_info()
		return
	if y >= World.G:
		# Kammer in der Nähe des Fingers suchen
		for r in 3:
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var ch := world.chamber_at(x + dx, y + dy)
					if ch != 0 and world.is_tunnel(x + dx, y + dy):
						var info: Array = colony.chamber_info(ch)
						hud.show_info(info[0], info[1], ch)
						return
		if world.is_tunnel(x, y):
			hud.show_info("GANG", [
				"AMEISEN: %d" % ants.count,
				"SOLDATEN: %d" % ants.count_role(Ant.R_SOLDIER),
				"GRABEN: %d" % ants.count_state(Ant.S_DIG),
			], 0)
		else:
			hud.show_info("ERDE", ["SCHICHT %d" % (World.layer_of(y) + 1), "TIEFE: %d" % (y - World.G)], 0)
		return
	# Oberfläche: Baum oder Busch in der Nähe?
	for s in world.sources:
		if absi(s.trunk - x) <= s.r and y >= s.cy - s.r:
			var n := 0
			for f in s.fruits:
				if f.alive:
					n += 1
			hud.show_info("BAUM" if s.kind == 0 else "BUSCH", ["FRÜCHTE: %d" % n, "SAMMLER: %d" % ants.count_state(Ant.S_FORAGE)], 0)
			return
	hud.hide_info()


# ---------------------------------------------------------------- Speichern und Laden

func save_game() -> void:
	if ants.count == 0:
		return
	var data := {
		"version": SAVE_VERSION,
		"world": world.to_dict(),
		"colony": colony.to_dict(),
		"ants": ants.to_dict(),
		"events": events.to_dict(),
		"phero": phero.to_dict(),
		"camera": [cam.position.x, cam.position.y, cam.zoom.x],
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Speichern fehlgeschlagen: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data))
	f.close()


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY or int(data.get("version", 0)) != SAVE_VERSION:
		return false
	if not world.from_dict(data.get("world", {})):
		return false
	phero.from_dict(data.get("phero", {}))
	colony.from_dict(data.get("colony", {}))
	ants.from_dict(data.get("ants", {}))
	events.from_dict(data.get("events", {}))
	var c: Array = data.get("camera", [])
	if c.size() == 3:
		cam.zoom = Vector2.ONE * float(c[2])
		cam.position = Vector2(float(c[0]), float(c[1]))
		cam._clamp()
	return ants.count > 0
