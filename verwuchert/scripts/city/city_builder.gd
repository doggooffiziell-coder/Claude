class_name CityBuilder
extends Node2D
## Phase 1: Stadtbau in isometrischer Ansicht. Raster, Bauen, Abreißen, Geld, Bautrupps,
## Strom und Wasser über das Straßennetz, Namen, Chronik, Tageszeit.
## Alle Spiellogik rechnet in Feldern. Iso wandelt Felder in Bildschirmpunkte.

signal toast(text: String, color: Color)
signal selection_changed(b: Dictionary)
signal payday(net: int)
signal chronicle_added(entry: Dictionary)
signal city_finished

const T := 32
const MARGIN := 4
const PAINT_TOOLS := ["house", "shop", "park", "demolish"]
const NO_TILE := Vector2i(-99, -99)
const DIRS := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
## Der Zielpunkt liegt so viele Spielpunkte über dem Finger, damit der Finger ihn nicht verdeckt.
const TOUCH_LIFT := 34.0
## Ab dieser Strecke gilt eine Berührung als Ziehen und nicht als Tippen.
const TAP_SLOP_MOUSE := 4.0
const TAP_SLOP_TOUCH := 9.0

@onready var world: Node2D = $World
@onready var ground: CityRenderer = $World/Ground
@onready var shadow_group: CanvasGroup = $World/Shadows
@onready var shadow_painter: ShadowPainter = $World/Shadows/Painter
@onready var light_pools: LightPools = $World/LightPools
@onready var objects: Node2D = $World/Objects
@onready var wires: Node2D = $World/Wires
@onready var particles: Particles = $World/Particles
@onready var top_overlay: TopOverlay = $World/TopOverlay
@onready var sky: SkyLayer = $World/Sky
@onready var camera: Camera2D = $Camera
@onready var traffic: Traffic = $Traffic

var city: Dictionary
var tool := ""
var hover := Vector2i.ZERO
var selected: Dictionary = {}
var speed := 1.0
var speed_index := 1
var anim_time := 0.0
var hour := 8.0
var night := 0.0
var entry_row := 8
var ghost_variant := 1

var roads: Dictionary = {}
var occupancy: Dictionary = {}
var building_views: Dictionary = {}
var tree_views: Array[TreeView] = []
var pole_views: Array[PoleView] = []
var powered_roads: Dictionary = {}
var watered_roads: Dictionary = {}
var road_count := 0
var occupied_houses := 0
var active_work := 0
var residents := 0
var power_load := 0
var power_cap := 0
var water_load := 0
var water_cap := 0
var income_parts := {"steuern": 0, "grundsteuer": 0, "laeden": 0, "fabriken": 0, "unterhalt": 0}

## Wird wahr, wenn alle Ladeschritte fertig sind. Vorher läuft nur der Ladebalken.
var loaded := false
## Zahl der Straßen, die noch gebaut werden. Der Boden zeichnet sie dann jedes Bild neu.
var roads_open := 0
## Zählt hoch, wenn sich die Masten ändern. Die Leitungen zeichnen sich nur dann neu.
var pole_version := 0

var _steps: Array = []
var _step_us := {}
var _step_i := 0
var _step_sub := 0.0
var _load_ui: CanvasLayer
var _load_label: Label
var _load_fill: ColorRect
var _forest: Array = []
var _forest_i := 0
var _nature_done := false
var _prewarm: Array = []
var _prewarm_i := 0
var _prewarm_done := false
var _prewarm_t := 0.0
var _view_i := 0
var _last_variant := {}

# Touch: zwei Finger bewegen die Karte und zoomen, ein Finger baut mit Vorschau.
var _touches := {}
var _gesture := false
var _gesture_dirty := false
var _g_center := Vector2.ZERO
var _g_dist := 1.0
var _finger_down := false
var _touch_pending := false

var _lit_mat: ShaderMaterial
var _status_t := 0.0
var _autosave_t := 0.0
var _dragging := false
var _drag_start := Vector2i.ZERO
var _panning := false
var _left_pan := false
var _pan_moved := 0.0
var _mouse_screen := Vector2(320, 180)
var _last_paint := NO_TILE
var _warned_drag := false
var _hinted_target := false
var _pond: PackedByteArray
var _shot_frames := -1


func _ready() -> void:
	# Die Welt bleibt aus, bis alles geladen ist. Der Ladebalken zeigt den Fortschritt.
	world.visible = false
	world.process_mode = Node.PROCESS_MODE_DISABLED
	traffic.process_mode = Node.PROCESS_MODE_DISABLED
	$HUD/Root.process_mode = Node.PROCESS_MODE_DISABLED
	if GameState.city.is_empty():
		GameState.new_game(int(GameState.user_args.get("seed", "-1")))
	city = GameState.city
	if not city.has("chronicle"):
		city.chronicle = []
	entry_row = int(city.h) / 2
	hour = float(city.hour)
	_pond = Terrain.ponds(int(city.seed), int(city.w), int(city.h), Config.integer("city/pond_count", 1))
	_lit_mat = ShaderMaterial.new()
	_lit_mat.shader = preload("res://shaders/lit.gdshader")
	world.material = _lit_mat
	for n in [objects, particles, top_overlay, sky, wires]:
		n.use_parent_material = true
	shadow_painter.builder = self
	light_pools.builder = self
	top_overlay.builder = self
	wires.builder = self
	traffic.setup(self, objects)
	sky.setup(self, map_screen_rect())
	_ensure_start_roads()
	_make_loader()
	_steps = [
		["Boden wird gemalt", _step_ground],
		["Wald wächst", _step_nature],
		["Stadt wird aufgebaut", _step_views],
		["Letzte Handgriffe", _step_finish],
	]


# Laden in Häppchen: jedes Bild bekommt rund 9 Millisekunden, der Rest bleibt für den Balken.

func _make_loader() -> void:
	_load_ui = CanvasLayer.new()
	_load_ui.layer = 40
	add_child(_load_ui)
	var root := Control.new()
	root.theme = UiTheme.get_theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_ui.add_child(root)
	var bg := ColorRect.new()
	bg.color = Pal.NIGHT
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	center.add_child(col)
	var title := Label.new()
	title.text = "Verwuchert"
	title.add_theme_font_size_override("font_size", PixelFont.SIZE * 2)
	title.add_theme_color_override("font_color", Pal.YELLOW)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	_load_label = Label.new()
	_load_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_load_label.custom_minimum_size = Vector2(180, 0)
	col.add_child(_load_label)
	var frame := ColorRect.new()
	frame.color = Pal.BLACK
	frame.custom_minimum_size = Vector2(164, 10)
	col.add_child(frame)
	var inner := ColorRect.new()
	inner.color = Pal.SLATE
	inner.position = Vector2(2, 2)
	inner.size = Vector2(160, 6)
	frame.add_child(inner)
	_load_fill = ColorRect.new()
	_load_fill.color = Pal.OCHRE
	_load_fill.position = Vector2(2, 2)
	_load_fill.size = Vector2(0, 6)
	frame.add_child(_load_fill)


func _run_loader() -> void:
	var t0 := Time.get_ticks_usec()
	while _step_i < _steps.size() and Time.get_ticks_usec() - t0 < 9000:
		var st: Array = _steps[_step_i]
		_load_label.text = "%s..." % st[0]
		var s0 := Time.get_ticks_usec()
		var finished: bool = st[1].call()
		_step_us[st[0]] = int(_step_us.get(st[0], 0)) + Time.get_ticks_usec() - s0
		if finished:
			_step_i += 1
			_step_sub = 0.0
	if loaded:
		if GameState.user_args.has("steptimes"):
			for k in _step_us:
				print("Ladeschritt %-26s %6.1f ms" % [k, _step_us[k] / 1000.0])
		return
	_load_fill.size.x = roundf(160.0 * (float(_step_i) + _step_sub) / float(_steps.size()))


func _step_ground() -> bool:
	if ground.job == null:
		ground.begin(self)
	var done := ground.step(8.0)
	_step_sub = ground.job.progress
	return done


func _step_nature() -> bool:
	if not _nature_done:
		_nature_done = true
		_spawn_nature()
		_forest = _forest_plan()
	var n := 0
	while _forest_i < _forest.size() and n < 24:
		_make_decor_tree(_forest[_forest_i])
		_forest_i += 1
		n += 1
	_step_sub = float(_forest_i) / maxi(1, _forest.size())
	return _forest_i >= _forest.size()


## Malt die Gebäude vor, die man am häufigsten braucht. Das läuft nach dem Start im Hintergrund,
## ein Bild alle paar Bilder, damit der Ladebalken kurz bleibt und später nichts ruckelt.
func _idle_prewarm(delta: float) -> void:
	if _prewarm_done or anim_time < 1.5:
		return
	_prewarm_t -= delta
	if _prewarm_t > 0.0:
		return
	_prewarm_t = 0.12
	if _prewarm.is_empty():
		for type in ["house", "shop", "park", "power_plant", "water_tower", "factory"]:
			_prewarm.append([type, "left"])
		_prewarm.append(["house", "right"])
		_prewarm.append(["shop", "right"])
	if _prewarm_i >= _prewarm.size():
		_prewarm_done = true
		return
	var it: Array = _prewarm[_prewarm_i]
	_prewarm_i += 1
	var variant := BuildingTypes.variant_for(it[0], 0)
	SpriteFactory.building(it[0], variant, _material_for(it[0], variant), it[1])


## Gebäude aus einem Spielstand bekommen ihre Ansicht, ein paar pro Aufruf.
func _step_views() -> bool:
	var list: Array = city.buildings
	var n := 0
	while _view_i < list.size() and n < 6:
		_add_view(list[_view_i])
		_view_i += 1
		n += 1
	_step_sub = float(_view_i) / maxi(1, list.size())
	return _view_i >= list.size()


func _step_finish() -> bool:
	ground.rebake_all()
	_update_status()
	_rebuild_poles()
	_setup_camera()
	_reroll_ghost()
	$HUD/Root.process_mode = Node.PROCESS_MODE_INHERIT
	$HUD/Root.setup(self)
	if float(city.time) < 1.0:
		set_speed(Settings.start_speed)
	if city.chronicle.is_empty():
		add_event("Die Stadt wird gegründet. Eine Landstraße führt aus dem Wald herein.")
	world.visible = true
	world.process_mode = Node.PROCESS_MODE_INHERIT
	traffic.process_mode = Node.PROCESS_MODE_INHERIT
	loaded = true
	_load_ui.queue_free()
	_debug_args()
	return true


func _debug_args() -> void:
	var a: Dictionary = GameState.user_args
	if a.has("demo"):
		_demo_city()
	if a.has("hour"):
		hour = float(a.hour)
	if a.has("finish"):
		# Nur für Tests: nach der Beispielstadt gleich in den Zeitraffer
		call_deferred("finish_city")
		return
	if a.has("shot"):
		_shot_frames = int(a.get("frames", "40"))
	if a.has("zoom"):
		camera.zoom = Vector2.ONE * float(a.zoom)
	if a.has("look"):
		var p: PackedStringArray = str(a.look).split(",")
		camera.position = Iso.to_screen(float(p[0]), float(p[1]))
		_clamp_camera()
	if a.has("tool"):
		tool = str(a.tool)
		var hp: PackedStringArray = str(a.get("hover", "12,5")).split(",")
		hover = Vector2i(int(hp[0]), int(hp[1]))
	if a.has("select"):
		var sp: PackedStringArray = str(a.select).split(",")
		selected = building_at(Vector2i(int(sp[0]), int(sp[1])))
		selection_changed.emit(selected)


# Aufbau

func _ensure_start_roads() -> void:
	if not city.buildings.is_empty() or float(city.time) > 0.0:
		return
	for x in 3:
		var b := GameState.add_building("road", x, entry_row)
		b.state = "done"
		b.progress = 1.0
	city.trees = city.trees.filter(func(t): return not (int(t.y) == entry_row and int(t.x) < 3))


func _spawn_nature() -> void:
	for t in city.trees:
		var tv := TreeView.new()
		objects.add_child(tv)
		tv.setup(t, self)
		tree_views.append(tv)


## Dichter Wald im Rand rund um das Baugebiet. Nur Deko, ohne Spielstand.
func _forest_plan() -> Array:
	return ForestPlan.make(city, MARGIN, entry_row)


func _make_decor_tree(t: Dictionary) -> void:
	var tv := TreeView.new()
	objects.add_child(tv)
	tv.setup(t, self, true)


func _add_view(b: Dictionary) -> void:
	for y in int(b.h):
		for x in int(b.w):
			occupancy[Vector2i(int(b.x) + x, int(b.y) + y)] = int(b.id)
	if b.type == "road":
		roads[Vector2i(int(b.x), int(b.y))] = b
		return
	var v := BuildingView.new()
	objects.add_child(v)
	v.setup(b, self)
	building_views[int(b.id)] = v


## Rechteck der ganzen Karte mit Rand auf dem Bildschirm.
func map_screen_rect() -> Rect2:
	var w: int = city.w
	var h: int = city.h
	var top := Iso.to_screen(-MARGIN, -MARGIN)
	var right := Iso.to_screen(w + MARGIN, -MARGIN)
	var bot := Iso.to_screen(w + MARGIN, h + MARGIN)
	var left := Iso.to_screen(-MARGIN, h + MARGIN)
	return Rect2(left.x, top.y, right.x - left.x, bot.y - top.y)


func _setup_camera() -> void:
	var r := map_screen_rect()
	var inner := Rect2(Iso.to_screen(0, int(city.h)).x, Iso.to_screen(0, 0).y, 0, 0)
	inner = inner
	camera.limit_left = int(r.position.x) + 120
	camera.limit_right = int(r.end.x) - 120
	camera.limit_top = int(r.position.y) + 40
	camera.limit_bottom = int(r.end.y) + 20
	camera.position = Iso.to_screen(6.0, entry_row + 1.0) if city.buildings.size() <= 3 else Iso.to_screen(int(city.w) * 0.42, int(city.h) * 0.55)
	_clamp_camera()


# Zeit und Ablauf

func _process(delta: float) -> void:
	if not loaded:
		_run_loader()
		return
	# Nach einer Pause oder einem Tab-Wechsel kommt ein riesiger Zeitsprung, den fangen wir ab
	delta = minf(delta, 0.1)
	if _gesture_dirty:
		_gesture_dirty = false
		if _gesture and _touches.size() >= 2:
			_update_gesture()
	anim_time += delta
	_idle_prewarm(delta)
	var dt := delta * speed
	if speed > 0.0:
		_tick(dt)
	night = DayCycle.night(hour)
	_lit_mat.set_shader_parameter("tint", DayCycle.tint(hour))
	shadow_group.visible = Settings.shadows
	shadow_group.self_modulate = Color(1, 1, 1, 0.34 * DayCycle.sun_strength(hour))
	_status_t -= delta
	if _status_t <= 0.0:
		_status_t = 0.4
		_update_status()
	_camera_keys(delta)
	if _shot_frames >= 0:
		_shot_frames -= 1
		if _shot_frames == 0:
			var img := get_viewport().get_texture().get_image()
			img.save_png(str(GameState.user_args.shot))
			get_tree().quit()


func _tick(dt: float) -> void:
	city.time = float(city.time) + dt
	var day_len := Config.num("city/day_seconds", 150.0)
	hour += dt * 24.0 / day_len
	if hour >= 24.0:
		hour -= 24.0
		city.day = int(city.day) + 1
	city.hour = hour
	_build_progress(dt)
	city.payday_timer = float(city.payday_timer) + dt
	var pd := Config.num("city/payday_seconds", 12.0)
	if float(city.payday_timer) >= pd:
		city.payday_timer = float(city.payday_timer) - pd
		_payday()
	_autosave_t += dt
	if _autosave_t >= Platform.autosave_seconds():
		_autosave_t = 0.0
		GameState.save_game()
	var target := Config.num("city/target_seconds", 480.0)
	if not _hinted_target and float(city.time) >= target:
		_hinted_target = true
		toast.emit("Deine Stadt ist bereit. Drück \"Stadt fertig\", wenn du willst.", Pal.YELLOW)
	var max_s := Config.num("city/max_seconds", 0.0)
	if max_s > 0.0 and float(city.time) >= max_s:
		toast.emit("Die Zeit ist um. Die Jahre beginnen.", Pal.ROSE)
		finish_city()


func time_left() -> float:
	var max_s := Config.num("city/max_seconds", 0.0)
	if max_s <= 0.0:
		return -1.0
	return maxf(0.0, max_s - float(city.time))


## Bautrupps arbeiten die Warteschlange der Reihe nach ab. Straßen bauen sich selbst.
func _build_progress(dt: float) -> void:
	var crews := Config.integer("city/crews", 2)
	var busy := 0
	var open_roads := 0
	for b in city.buildings.duplicate():
		if b.state == "done":
			continue
		if b.type == "road":
			open_roads += 1
		if BuildingTypes.uses_crew(b.type):
			if busy >= crews:
				b.state = "queued"
				continue
			busy += 1
		b.state = "building"
		b.progress = float(b.progress) + dt / BuildingTypes.build_time(b.type)
		if float(b.progress) >= 1.0:
			_complete(b)
			if b.type == "road":
				open_roads -= 1
	roads_open = open_roads


func _complete(b: Dictionary) -> void:
	GameState.finish_building(b)
	if b.type == "road":
		ground.road_changed(Vector2i(int(b.x), int(b.y)))
	if b.type != "road":
		_name_building(b)
		var anchor := Iso.bottom(int(b.x), int(b.y), int(b.w), int(b.h))
		var hgt: float = BuildingTypes.info(b.type).get("height", 20)
		particles.emit("spark", anchor - Vector2(0, hgt * 0.6 + 10), 14)
		particles.emit("dust", anchor - Vector2(0, 6), 10)
		particles.emit("text", anchor - Vector2(0, hgt + 26), 1, {"text": "Fertig!", "col": Pal.LEAF_L})
	_update_status()
	_rebuild_poles()


## Läden, Fabriken und Versorger bekommen beim Fertigwerden ihren Namen.
func _name_building(b: Dictionary) -> void:
	var seed_value: int = city.seed
	var street := address(b)
	match b.type:
		"shop":
			b.name = Names.shop(seed_value, int(b.id), BuildingArt.shop_kind(int(b.variant)))
			add_event("%s öffnet%s." % [b.name, (" " + _in_street(street)) if street != "" else ""])
		"factory":
			b.name = Names.factory(seed_value, int(b.id))
			add_event("Die %s nimmt die Arbeit auf." % b.name)
		"power_plant":
			b.name = "Kraftwerk" + ((" " + _at_street(street)) if street != "" else "")
			add_event("Das Kraftwerk läuft. Strom fließt über die Straßen.")
		"water_tower":
			b.name = "Wasserturm" + ((" " + _at_street(street)) if street != "" else "")
			add_event("Der Wasserturm ist gefüllt.")
		"park":
			b.name = "Park" + ((" " + _at_street(street)) if street != "" else "")


func _in_street(addr: String) -> String:
	return Names.place(addr, "in")


func _at_street(addr: String) -> String:
	return Names.place(addr, "an")


func crews_busy() -> int:
	var n := 0
	for b in city.buildings:
		if b.state == "building" and BuildingTypes.uses_crew(b.type):
			n += 1
	return n


func queue_length() -> int:
	var n := 0
	for b in city.buildings:
		if b.state == "queued":
			n += 1
	return n


func _payday() -> void:
	var net := 0
	for v in building_views.values():
		var amount: int = v.status.get("income", 0)
		if amount == 0:
			continue
		net += amount
		var col := Pal.YELLOW if amount > 0 else Pal.ROSE
		var txt := ("+%d" % amount) if amount > 0 else str(amount)
		particles.emit("text", v.top_point() - Vector2(0, 6), 1, {"text": txt, "col": col})
	city.money = int(city.money) + net
	payday.emit(net)


func set_speed(index: int) -> void:
	var speeds: Array = Config.get_value("city/speeds", [1, 2, 3])
	speed_index = clampi(index, 0, speeds.size())
	speed = 0.0 if speed_index == 0 else float(speeds[speed_index - 1])


func finish_city() -> void:
	tool = ""
	city.hour = hour
	add_event("Die letzte Baustelle schließt. Dann wird es still in der Stadt.")
	GameState.phase = 2
	GameState.save_game()
	city_finished.emit()
	GameState.go_to_phase(2)


# Chronik

func add_event(text: String) -> void:
	var e := {"day": int(city.day), "hour": snappedf(hour, 0.1), "text": text}
	city.chronicle.append(e)
	if city.chronicle.size() > 200:
		city.chronicle.pop_front()
	chronicle_added.emit(e)


# Straßennamen und Adressen

## Adresse eines Gebäudes: Straße auf der Türseite und Hausnummer.
func address(b: Dictionary) -> String:
	var t := road_next_to(b)
	if t == NO_TILE or t.x < 0:
		return ""
	var x0 := int(b.x)
	var y0 := int(b.y)
	var w := int(b.w)
	var h := int(b.h)
	var seed_value: int = city.seed
	# Liegt die Straße vorne oder hinten, läuft sie entlang U, sonst entlang V
	if t.y == y0 + h or t.y == y0 - 1:
		var no := t.x * 2 + (1 if t.y == y0 + h else 2)
		return "%s %d" % [Names.street(seed_value, 0, t.y), no]
	var no2 := t.y * 2 + (1 if t.x == x0 + w else 2)
	return "%s %d" % [Names.street(seed_value, 1, t.x), no2]


func street_of_tile(t: Vector2i) -> String:
	var m := road_mask(t)
	var seed_value: int = city.seed
	if (m & (RoadArt.E | RoadArt.W)) != 0 or m == 0:
		return Names.street(seed_value, 0, t.y)
	return Names.street(seed_value, 1, t.x)


# Versorgung über das Straßennetz

func _plant_roads(b: Dictionary) -> Array:
	var out := []
	var x0 := int(b.x)
	var y0 := int(b.y)
	for x in range(x0 - 1, x0 + int(b.w) + 1):
		for y in range(y0 - 1, y0 + int(b.h) + 1):
			var inside_fp := x >= x0 and y >= y0 and x < x0 + int(b.w) and y < y0 + int(b.h)
			var corner := (x == x0 - 1 or x == x0 + int(b.w)) and (y == y0 - 1 or y == y0 + int(b.h))
			if inside_fp or corner:
				continue
			if is_road(Vector2i(x, y)):
				out.append(Vector2i(x, y))
	return out


func _road_dist(starts: Array) -> Dictionary:
	var dist := {}
	var queue: Array[Vector2i] = []
	for s in starts:
		dist[s] = 0
		queue.append(s)
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		for d in DIRS:
			var n: Vector2i = cur + d
			if not dist.has(n) and is_road(n):
				dist[n] = int(dist[cur]) + 1
				queue.append(n)
	return dist


## Verteilt Strom oder Wasser von jedem Versorger über die Straßen an die nächsten Verbraucher,
## bis seine Leistung aufgebraucht ist. Gibt {id: true} der versorgten Gebäude zurück.
func _supply(source_type: String, consumers: Dictionary, reached_roads: Dictionary) -> Dictionary:
	var served := {}
	var cap_total := 0
	var load := 0
	var cap_each := int(Config.building(source_type).get("capacity", 20))
	for v in building_views.values():
		var src: Dictionary = v.data
		if src.type != source_type or src.state != "done":
			continue
		var starts := _plant_roads(src)
		if starts.is_empty():
			continue
		cap_total += cap_each
		var dist := _road_dist(starts)
		for t in dist:
			reached_roads[t] = true
		var cands := []
		for id in consumers:
			if served.has(id):
				continue
			var cb: Dictionary = building_views[id].data
			var best := 9999
			for rt in _plant_roads(cb):
				if dist.has(rt):
					best = mini(best, int(dist[rt]))
			if best < 9999:
				cands.append([best, id])
		cands.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
		var left := cap_each
		for c in cands:
			var need: int = consumers[c[1]]
			if need > left:
				continue
			left -= need
			load += need
			served[c[1]] = true
	if source_type == "power_plant":
		power_cap = cap_total
		power_load = load
	else:
		water_cap = cap_total
		water_load = load
	return served


func has_power(b: Dictionary) -> bool:
	var v = building_views.get(int(b.get("id", -1)))
	return v != null and v.status.get("power", false)


func _update_status() -> void:
	road_count = 0
	for t in roads:
		if roads[t].state == "done":
			road_count += 1
	var house_cfg := Config.building("house")
	var shop_cfg := Config.building("shop")
	var fac_cfg := Config.building("factory")
	var park_cfg := Config.building("park")
	# Verbraucher sammeln
	var power_need := {}
	var water_need := {}
	for v in building_views.values():
		var b: Dictionary = v.data
		if b.state != "done":
			continue
		match b.type:
			"house":
				power_need[int(b.id)] = 1
				water_need[int(b.id)] = 1
			"shop":
				power_need[int(b.id)] = 1
			"factory":
				power_need[int(b.id)] = int(fac_cfg.get("power_use", 3))
	var new_powered := {}
	var new_watered := {}
	var powered := _supply("power_plant", power_need, new_powered)
	var watered := _supply("water_tower", water_need, new_watered)
	var roads_changed := new_powered.size() != powered_roads.size()
	powered_roads = new_powered
	watered_roads = new_watered
	occupied_houses = 0
	active_work = 0
	income_parts = {"steuern": 0, "grundsteuer": 0, "laeden": 0, "fabriken": 0, "unterhalt": 0}
	# Erst Häuser, dann der Rest, weil Läden bewohnte Häuser zählen
	for pass_type in ["house", "other"]:
		for v in building_views.values():
			var b: Dictionary = v.data
			if (b.type == "house") != (pass_type == "house"):
				continue
			var old: Dictionary = v.status
			var st := {"needs": [], "income": 0}
			if b.state != "done":
				v.status = st
				continue
			var road := touches_road(b)
			var power: bool = powered.has(int(b.id))
			var water: bool = watered.has(int(b.id))
			st.road = road
			st.power = power
			st.water = water
			match b.type:
				"house":
					if not road:
						st.needs.append("road_need")
					else:
						if not power: st.needs.append("bolt")
						if not water: st.needs.append("drop")
					st.occupied = road and power and water
					if st.occupied:
						occupied_houses += 1
						var inc := float(house_cfg.get("residents", 4)) * float(house_cfg.get("tax_per_resident", 5))
						var parks: int = mini(_count_near(b, "park", float(park_cfg.get("radius", 3))), int(house_cfg.get("park_bonus_max", 2)))
						inc += parks * float(house_cfg.get("park_bonus", 4))
						st.parks = parks
						if _count_near(b, "factory", float(fac_cfg.get("pollution_radius", 3))) > 0:
							inc *= 1.0 - float(house_cfg.get("factory_malus", 0.3))
							st.polluted = true
						st.income = int(round(inc))
						income_parts.steuern += st.income
						if not old.get("occupied", false):
							_move_in(b)
					else:
						# Grundsteuer: auch leere Häuser bringen etwas Geld
						st.income = int(house_cfg.get("base_tax", 6))
						income_parts.grundsteuer += st.income
						if old.get("occupied", false) and b.has("family"):
							var why := "Strom" if not power else ("Wasser" if not water else "Straße")
							add_event("Familie %s hat kein %s mehr und zieht aus." % [b.family, why] if why != "Straße" else "Familie %s ist von der Straße abgeschnitten." % b.family)
				"shop":
					var customers := _count_near(b, "house", float(shop_cfg.get("customer_radius", 6)), "occupied")
					st.customers = customers
					if not road: st.needs.append("road_need")
					elif not power: st.needs.append("bolt")
					elif customers == 0: st.needs.append("people_need")
					st.active = road and power and customers > 0
					if st.active:
						active_work += 1
						st.income = mini(int(shop_cfg.get("income", 20)) + customers * int(shop_cfg.get("income_per_house", 5)), int(shop_cfg.get("max_income", 75)))
						income_parts.laeden += st.income
				"factory":
					if not road: st.needs.append("road_need")
					elif not power: st.needs.append("bolt")
					st.active = road and power
					if st.active:
						active_work += 1
						st.income = int(fac_cfg.get("income", 90))
						income_parts.fabriken += st.income
				"water_tower", "power_plant":
					st.active = road
					if not road: st.needs.append("road_need")
					st.income = -int(Config.building(b.type).get("upkeep", 0))
					income_parts.unterhalt += st.income
				"park":
					st.active = true
			v.status = st
	residents = occupied_houses * int(house_cfg.get("residents", 4))
	if roads_changed:
		_rebuild_poles()


## Eine Familie zieht ein. Beim ersten Mal bekommt das Haus Namen und Bewohner.
func _move_in(b: Dictionary) -> void:
	var count := int(Config.building("house").get("residents", 4))
	if not b.has("family"):
		b.family = Names.family(int(city.seed), int(b.id))
		b.people = Names.residents(int(city.seed), int(b.id), count)
		var addr := address(b)
		add_event("Familie %s zieht ein%s." % [b.family, (" " + _in_street(addr)) if addr != "" else ""])
	else:
		add_event("Familie %s ist zurück." % b.family)


func _count_near(b: Dictionary, type: String, radius: float, need_status := "") -> int:
	var c := Vector2(int(b.x) + int(b.w) * 0.5, int(b.y) + int(b.h) * 0.5)
	var n := 0
	for v in building_views.values():
		var o: Dictionary = v.data
		if o == b or o.type != type or o.state != "done":
			continue
		if need_status != "" and not v.status.get(need_status, false):
			continue
		var oc := Vector2(int(o.x) + int(o.w) * 0.5, int(o.y) + int(o.h) * 0.5)
		if c.distance_to(oc) <= radius:
			n += 1
	return n


func touches_road(b: Dictionary) -> bool:
	return road_next_to(b) != NO_TILE


func income_per_payday() -> int:
	var n := 0
	for k in income_parts:
		n += int(income_parts[k])
	return n


# Straßen und Wege

func entry_tile() -> Vector2i:
	return Vector2i(-MARGIN, entry_row)


func is_road(t: Vector2i) -> bool:
	if t.y == entry_row and t.x < 0 and t.x >= -MARGIN:
		return true
	return roads.has(t) and roads[t].state == "done"


func _road_any(t: Vector2i) -> bool:
	if t.y == entry_row and t.x < 0 and t.x >= -MARGIN:
		return true
	return roads.has(t)


func road_mask(t: Vector2i) -> int:
	var m := 0
	if _road_any(t + Vector2i(0, -1)): m |= RoadArt.N
	if _road_any(t + Vector2i(1, 0)): m |= RoadArt.E
	if _road_any(t + Vector2i(0, 1)): m |= RoadArt.S
	if _road_any(t + Vector2i(-1, 0)): m |= RoadArt.W
	return m


func road_tiles() -> Array:
	var out := []
	for t in roads:
		if roads[t].state == "done":
			out.append(t)
	return out


func road_next_to(b: Dictionary) -> Vector2i:
	var x0 := int(b.x)
	var y0 := int(b.y)
	var w := int(b.w)
	var h := int(b.h)
	# Erst die Seite mit der Tür
	var facing := str(b.get("facing", "left"))
	var order := ["s", "e", "n", "w"] if facing != "right" else ["e", "s", "n", "w"]
	for side in order:
		match side:
			"s":
				for x in range(x0, x0 + w):
					if is_road(Vector2i(x, y0 + h)):
						return Vector2i(x, y0 + h)
			"e":
				for y in range(y0, y0 + h):
					if is_road(Vector2i(x0 + w, y)):
						return Vector2i(x0 + w, y)
			"n":
				for x in range(x0, x0 + w):
					if is_road(Vector2i(x, y0 - 1)):
						return Vector2i(x, y0 - 1)
			"w":
				for y in range(y0, y0 + h):
					if is_road(Vector2i(x0 - 1, y)):
						return Vector2i(x0 - 1, y)
	return NO_TILE


## Auf welcher Seite die Tür liegt: an der Straße, wenn möglich.
func facing_for(type: String, t: Vector2i) -> String:
	var size := BuildingTypes.size_of(type)
	for x in range(t.x, t.x + size.x):
		if _road_any(Vector2i(x, t.y + size.y)):
			return "left"
	for y in range(t.y, t.y + size.y):
		if _road_any(Vector2i(t.x + size.x, y)):
			return "right"
	for x in range(t.x, t.x + size.x):
		if _road_any(Vector2i(x, t.y - 1)):
			return "back"
	for y in range(t.y, t.y + size.y):
		if _road_any(Vector2i(t.x - 1, y)):
			return "back"
	return "left"


func road_path(a: Vector2i, b: Vector2i) -> Array:
	if a == b:
		return [a]
	var prev := {a: a}
	var queue: Array[Vector2i] = [a]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == b:
			break
		for d in DIRS:
			var n: Vector2i = cur + d
			if not prev.has(n) and is_road(n):
				prev[n] = cur
				queue.append(n)
	if not prev.has(b):
		return []
	var path := [b]
	var cur2 := b
	while cur2 != a:
		cur2 = prev[cur2]
		path.push_front(cur2)
	return path


## Bodenpunkt (in Feldern) vor der Tür.
func door_point(b: Dictionary) -> Vector2:
	var x0 := float(b.x)
	var y0 := float(b.y)
	var w := float(b.w)
	var h := float(b.h)
	if str(b.get("facing", "left")) == "right":
		return Vector2(x0 + w + 0.02, y0 + h * 0.5)
	return Vector2(x0 + w * 0.5, y0 + h + 0.02)


func occupied_house_list() -> Array:
	var out := []
	for v in building_views.values():
		if v.data.type == "house" and v.status.get("occupied", false):
			out.append(v.data)
	return out


func walk_goals() -> Array:
	var out := []
	for v in building_views.values():
		var b: Dictionary = v.data
		if b.state != "done":
			continue
		if b.type in ["shop", "park"] or (b.type == "house" and v.status.get("occupied", false)):
			out.append(b)
	return out


## Strommasten mit Laterne stehen nur an Straßen, die Strom führen.
func _rebuild_poles() -> void:
	for pv in pole_views:
		pv.queue_free()
	pole_views.clear()
	for t in powered_roads:
		if t.x < 0 or (t.x + t.y) % 2 != 0:
			continue
		var m := road_mask(t)
		var g := Vector2.ZERO
		if not (m & RoadArt.S):
			g = Vector2(t.x + 0.22, t.y + 0.92)
		elif not (m & RoadArt.E):
			g = Vector2(t.x + 0.92, t.y + 0.22)
		elif not (m & RoadArt.N):
			g = Vector2(t.x + 0.78, t.y + 0.08)
		elif not (m & RoadArt.W):
			g = Vector2(t.x + 0.08, t.y + 0.78)
		else:
			g = Vector2(t.x + 0.92, t.y + 0.92)
		var pv := PoleView.new()
		objects.add_child(pv)
		pv.setup(g, t, self)
		pole_views.append(pv)
	pole_version += 1


# Bauen

func select_tool(name: String) -> void:
	tool = name if tool != name else ""
	if tool != "":
		selected = {}
		selection_changed.emit(selected)
	_reroll_ghost()


func _reroll_ghost() -> void:
	ghost_variant = _pick_variant(tool)


## Wählt aus einer festen kleinen Menge, damit Bilder wiederverwendet werden und nichts ruckelt.
func _pick_variant(type: String) -> int:
	if not BuildingTypes.VARIANTS.has(type):
		return randi() % 10000
	var n := BuildingTypes.variant_count(type)
	var i := randi() % n
	if n > 1 and i == int(_last_variant.get(type, -1)):
		i = (i + 1) % n
	_last_variant[type] = i
	return BuildingTypes.variant_for(type, i)


func _material_for(type: String, variant: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = variant
	return BuildingTypes.roll_material(type, rng)


func ghost_material() -> String:
	if tool == "" or tool == "demolish":
		return ""
	return _material_for(tool, ghost_variant)


## Ändert sich diese Zahl, muss die Vorschau am Boden neu gezeichnet werden.
func preview_sig() -> int:
	return hash([tool, hover, _dragging, _drag_start if _dragging else Vector2i.ZERO, _touch_pending])


func inside(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.x < int(city.w) and t.y < int(city.h)


func hover_inside() -> bool:
	return inside(hover)


func hover_type() -> String:
	var b := building_at(hover)
	return b.type if not b.is_empty() else ""


func is_pond(t: Vector2i) -> bool:
	return inside(t) and _pond[t.y * int(city.w) + t.x] != 0


func building_at(t: Vector2i) -> Dictionary:
	if not occupancy.has(t):
		return {}
	return GameState.building_by_id(occupancy[t])


func trees_in(r: Rect2i) -> Array:
	var out := []
	for tv in tree_views:
		if r.has_point(tv.tile()):
			out.append(tv)
	return out


func can_place(type: String, t: Vector2i) -> bool:
	var size := BuildingTypes.size_of(type)
	for y in size.y:
		for x in size.x:
			var p := t + Vector2i(x, y)
			if not inside(p) or occupancy.has(p) or is_pond(p):
				return false
	return true


func place_cost(type: String, t: Vector2i) -> int:
	var size := BuildingTypes.size_of(type)
	return BuildingTypes.cost(type) + trees_in(Rect2i(t, size)).size() * Config.integer("city/tree_clear_cost", 5)


func place(type: String, t: Vector2i, quiet := false) -> bool:
	if not can_place(type, t):
		if not quiet:
			var reason := "Hier ist kein Platz."
			if is_pond(t):
				reason = "Im Teich kannst du nicht bauen."
			elif not inside(t) or not inside(t + BuildingTypes.size_of(type) - Vector2i.ONE):
				reason = "Das liegt außerhalb der Stadt."
			toast.emit(reason, Pal.ROSE)
		return false
	var cost := place_cost(type, t)
	if cost > int(city.money):
		if not _warned_drag:
			toast.emit("Zu wenig Geld. Du brauchst %d." % cost, Pal.ROSE)
			_warned_drag = true
		return false
	var size := BuildingTypes.size_of(type)
	for tv in trees_in(Rect2i(t, size)):
		_remove_tree(tv)
	var b: Dictionary
	if type == "road":
		b = GameState.add_building(type, t.x, t.y)
	else:
		b = GameState.add_building(type, t.x, t.y, ghost_variant, ghost_material())
		b.facing = facing_for(type, t)
	city.money = int(city.money) - cost
	_add_view(b)
	if type == "road":
		ground.road_changed(t)
	var anchor := Iso.bottom(t.x, t.y, size.x, size.y)
	particles.emit("dust", anchor - Vector2(0, 8), 6 if type != "road" else 3)
	if type != "road":
		particles.emit("text", anchor - Vector2(0, 40), 1, {"text": "-%d" % cost, "col": Pal.ROSE, "life": 1.0})
		_reroll_ghost()
		if queue_length() > 0 and BuildingTypes.uses_crew(type) and not quiet:
			var q := queue_length()
			toast.emit("Alle Bautrupps arbeiten. %d %s wartet." % [q, "Bau" if q == 1 else "Baustellen"], Pal.SAND)
	_update_status()
	return true


func _remove_tree(tv: TreeView) -> void:
	tree_views.erase(tv)
	city.trees.erase(tv.data)
	if tv.data.kind != "rock":
		for i in 8:
			particles.emit("leaf", tv.position + Vector2(randf_range(-8, 8), 0), 1, {"z": randf_range(8, 28)})
	particles.emit("dust", tv.position, 5)
	tv.queue_free()


func place_road_path(path: Array) -> void:
	var placed := 0
	var spent := 0
	for t in path:
		if roads.has(t):
			continue
		var before := int(city.money)
		if place("road", t, true):
			placed += 1
			spent += before - int(city.money)
		elif int(city.money) < place_cost("road", t):
			toast.emit("Das Geld reicht nicht für die ganze Straße.", Pal.ROSE)
			break
	if placed > 0:
		var last: Vector2i = path[path.size() - 1]
		particles.emit("text", Iso.center(last) - Vector2(0, 12), 1, {"text": "-%d" % spent, "col": Pal.ROSE, "life": 1.0})


func road_preview() -> Array:
	if not _dragging or tool != "road":
		return [hover]
	return _l_path(_drag_start, hover)


## Weg in L-Form: erst die längere Richtung, dann die kürzere.
func _l_path(a: Vector2i, b: Vector2i) -> Array:
	var out := []
	var d := b - a
	var corner := Vector2i(b.x, a.y) if absi(d.x) >= absi(d.y) else Vector2i(a.x, b.y)
	for p in [[a, corner], [corner, b]]:
		var from: Vector2i = p[0]
		var to: Vector2i = p[1]
		var step := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
		var cur := from
		if not out.has(cur):
			out.append(cur)
		while cur != to:
			cur += step
			if not out.has(cur):
				out.append(cur)
	return out


func demolish(t: Vector2i) -> void:
	var b := building_at(t)
	if b.is_empty():
		for tv in trees_in(Rect2i(t, Vector2i.ONE)):
			var cost := Config.integer("city/tree_clear_cost", 5)
			if int(city.money) >= cost:
				city.money = int(city.money) - cost
				_remove_tree(tv)
		return
	if b.type == "road" and int(b.y) == entry_row and int(b.x) == 0:
		toast.emit("Die Zufahrt bleibt. Sonst kommt niemand in die Stadt.", Pal.SAND)
		return
	var refund := BuildingTypes.cost(b.type)
	if b.state == "done":
		refund = int(refund * Config.num("city/demolish_refund", 0.5))
	city.money = int(city.money) + refund
	for y in int(b.h):
		for x in int(b.w):
			var p := Vector2i(int(b.x) + x, int(b.y) + y)
			occupancy.erase(p)
			traffic.clear_tile(p)
	var anchor := Iso.bottom(int(b.x), int(b.y), int(b.w), int(b.h))
	if b.type == "road":
		roads.erase(Vector2i(int(b.x), int(b.y)))
		ground.road_changed(Vector2i(int(b.x), int(b.y)))
	else:
		var v: Node = building_views.get(int(b.id))
		if v:
			v.queue_free()
		building_views.erase(int(b.id))
		if b.has("family"):
			add_event("Das Haus der Familie %s wird abgerissen." % b.family)
		elif b.has("name"):
			add_event("%s wird abgerissen." % b.name)
	for i in 3:
		particles.emit("dust", anchor + Vector2(randf_range(-14, 14), -randf_range(2, 20)), 6)
	particles.emit("smoke", anchor - Vector2(0, 10), 4, {"size": 1.6, "dark": false})
	particles.emit("text", anchor - Vector2(0, 30), 1, {"text": "+%d" % refund, "col": Pal.YELLOW, "life": 1.0})
	if selected == b:
		selected = {}
		selection_changed.emit(selected)
	GameState.remove_building(b)
	_update_status()
	_rebuild_poles()


# Eingabe

## Rohe Berührungen: zwei Finger bewegen die Karte und zoomen.
func _input(event: InputEvent) -> void:
	if not loaded:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() == 2 and not _gesture:
				_begin_gesture()
		else:
			_touches.erase(event.index)
			if _touches.is_empty():
				_gesture = false
	elif event is InputEventScreenDrag:
		# Beide Finger kommen als getrennte Ereignisse. Ausgewertet wird einmal pro Bild,
		# sonst sieht die Geste dazwischen einen schiefen Abstand.
		_touches[event.index] = event.position
		_gesture_dirty = true


func _begin_gesture() -> void:
	_gesture = true
	# Was der erste Finger gerade angefangen hat, wird abgebrochen
	_dragging = false
	_left_pan = false
	_touch_pending = false
	_finger_down = false
	var pts := _touches.values()
	_g_center = (pts[0] + pts[1]) * 0.5
	_g_dist = maxf(8.0, pts[0].distance_to(pts[1]))


func _update_gesture() -> void:
	var pts := _touches.values()
	var c: Vector2 = (pts[0] + pts[1]) * 0.5
	var d := maxf(8.0, pts[0].distance_to(pts[1]))
	camera.position -= (c - _g_center) / camera.zoom.x
	_g_center = c
	var ratio := d / _g_dist
	if ratio > 1.3 and camera.zoom.x < 2.0:
		_mouse_screen = c
		set_zoom(2)
		_g_dist = d
	elif ratio < 0.77 and camera.zoom.x > 1.0:
		_mouse_screen = c
		set_zoom(1)
		_g_dist = d
	_clamp_camera()


func _unhandled_input(event: InputEvent) -> void:
	if not loaded:
		return
	# Während zwei Finger auf dem Bild sind, zählt der zweite Finger nicht als Maus
	if _gesture and event is InputEventMouse:
		return
	if event is InputEventMouse:
		_mouse_screen = event.position
	if event is InputEventMouseMotion:
		_update_hover()
		if _panning or _left_pan:
			var d: Vector2 = event.relative / camera.zoom
			camera.position -= d
			_pan_moved += d.length()
			_clamp_camera()
		elif _dragging and tool in PAINT_TOOLS and hover != _last_paint and not _touch_pending:
			_last_paint = hover
			if tool == "demolish":
				demolish(hover)
			elif can_place(tool, hover):
				place(tool, hover, true)
	elif event is InputEventMouseButton:
		_update_hover()
		var touch: bool = event.device == InputEvent.DEVICE_ID_EMULATION
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_left_down(touch)
				else:
					_left_up(touch)
			MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				if event.pressed:
					_panning = true
					_pan_moved = 0.0
				else:
					_panning = false
					if event.button_index == MOUSE_BUTTON_RIGHT and _pan_moved < TAP_SLOP_MOUSE:
						cancel()
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					set_zoom(2)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					set_zoom(1)
	elif event is InputEventKey and event.pressed and not event.echo:
		_key(event)


func _key(event: InputEventKey) -> void:
	var tools := BuildingTypes.ORDER
	match event.keycode:
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7:
			select_tool(tools[event.keycode - KEY_1])
		KEY_X, KEY_DELETE:
			select_tool("demolish")
		KEY_SPACE:
			set_speed(1 if speed_index == 0 else 0)
		KEY_F5:
			if GameState.save_game():
				toast.emit("Gespeichert.", Pal.LEAF_L)
		KEY_EQUAL, KEY_KP_ADD:
			set_zoom(2)
		KEY_MINUS, KEY_KP_SUBTRACT:
			set_zoom(1)
		_:
			return
	get_viewport().set_input_as_handled()


func cancel() -> bool:
	if tool != "":
		tool = ""
		_dragging = false
		_touch_pending = false
		return true
	if not selected.is_empty():
		selected = {}
		selection_changed.emit(selected)
		return true
	return false


## touch ist wahr, wenn ein Finger die Maus ausgelöst hat. Dann baut erst das Loslassen,
## so sieht man die Vorschau und kann sie mit dem Finger verschieben.
func _left_down(touch := false) -> void:
	_warned_drag = false
	_finger_down = touch
	if touch:
		_update_hover()
	if tool == "":
		# Ohne Werkzeug: Ziehen bewegt die Karte, ein Tippen wählt ein Gebäude
		_left_pan = true
		_pan_moved = 0.0
		return
	if not hover_inside() and not touch:
		return
	_dragging = true
	_last_paint = hover
	match tool:
		"road":
			_drag_start = hover
		"demolish":
			if touch:
				_touch_pending = true
			else:
				demolish(hover)
		_:
			if touch:
				_touch_pending = true
			else:
				place(tool, hover)


func _left_up(touch := false) -> void:
	_finger_down = false
	if _left_pan:
		_left_pan = false
		if _pan_moved < (TAP_SLOP_TOUCH if touch else TAP_SLOP_MOUSE):
			var b := _pick_building()
			selected = b
			selection_changed.emit(selected)
		return
	if _dragging and tool == "road":
		place_road_path(_l_path(_drag_start, hover))
	elif _dragging and _touch_pending:
		if tool == "demolish":
			demolish(hover)
		elif hover_inside():
			place(tool, hover)
	_touch_pending = false
	_dragging = false


## Wählt das Gebäude unter der Maus. Hohe Gebäude ragen über andere Felder,
## darum zählt auch ein Klick auf ihr Bild.
func _pick_building() -> Dictionary:
	var b := building_at(hover)
	if not b.is_empty() and b.type != "road":
		return b
	var p := mouse_world()
	var best: Dictionary = {}
	var best_y := -99999.0
	for v in building_views.values():
		if v.hit(p) and v.position.y > best_y:
			best_y = v.position.y
			best = v.data
	return best


func mouse_world() -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * _mouse_screen


func _update_hover() -> void:
	var p := mouse_world()
	# Gebäude schweben über dem Finger, damit er sie nicht verdeckt. Straßen und Abriss treffen genau das Feld unter dem Finger.
	if _finger_down and tool != "" and tool != "road" and tool != "demolish":
		p.y -= TOUCH_LIFT / camera.zoom.x
	var size := BuildingTypes.size_of(tool) if tool in BuildingTypes.INFO else Vector2i.ONE
	var t := Iso.to_tile(p) - Vector2((size.x - 1) * 0.5, (size.y - 1) * 0.5)
	hover = Vector2i(floori(t.x), floori(t.y))
	if not _dragging and tool == "road":
		_drag_start = hover


func _camera_keys(delta: float) -> void:
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): v.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): v.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): v.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): v.y += 1
	if v != Vector2.ZERO:
		camera.position += v.normalized() * 240.0 * delta / camera.zoom.x
		_clamp_camera()
		_update_hover()


func _clamp_camera() -> void:
	var half := get_viewport_rect().size * 0.5 / camera.zoom
	camera.position.x = clampf(camera.position.x, camera.limit_left + half.x, maxf(camera.limit_left + half.x, camera.limit_right - half.x))
	camera.position.y = clampf(camera.position.y, camera.limit_top + half.y, maxf(camera.limit_top + half.y, camera.limit_bottom - half.y))
	camera.position = camera.position.round()


## Wechselt zwischen Zoom 1 und 2 um die Mitte des Bildes. Für den Knopf auf dem Handy.
func zoom_toggle() -> void:
	_mouse_screen = get_viewport().get_visible_rect().size * 0.5
	set_zoom(1 if camera.zoom.x > 1.5 else 2)


func set_zoom(z: int) -> void:
	var before := mouse_world()
	camera.zoom = Vector2(z, z)
	camera.force_update_scroll()
	var after := mouse_world()
	camera.position += before - after
	_clamp_camera()


# Beispielstadt für Tests und Bilder

func _demo_city() -> void:
	city.money = 99999
	var plan := [
		["road_h", 3, 8, 20], ["road_v", 6, 3, 14], ["road_v", 14, 3, 14], ["road_v", 20, 4, 13],
		["road_h", 6, 3, 18], ["road_h", 6, 13, 15], ["road_h", 14, 11, 7],
		["power_plant", 3, 9], ["water_tower", 10, 9],
		["house", 7, 7], ["house", 8, 7], ["house", 9, 7], ["house", 11, 7], ["house", 12, 7],
		["house", 7, 9], ["house", 8, 9], ["house", 12, 9], ["house", 13, 9],
		["house", 7, 2], ["house", 8, 2], ["house", 10, 2], ["house", 12, 2],
		["shop", 15, 7], ["shop", 16, 7], ["park", 10, 7], ["park", 15, 9], ["power_plant", 16, 4],
		["factory", 17, 9], ["house", 15, 2], ["house", 16, 2], ["shop", 18, 7],
		["park", 11, 9], ["house", 7, 12], ["house", 8, 12], ["house", 9, 12], ["house", 12, 12], ["house", 13, 12],
		["house", 21, 6], ["house", 21, 7], ["shop", 21, 9], ["park", 22, 9], ["house", 5, 9], ["house", 5, 7],
	]
	for item in plan:
		match item[0]:
			"road_h":
				for x in range(item[1], item[3] + 1):
					if not roads.has(Vector2i(x, item[2])):
						place("road", Vector2i(x, item[2]), true)
			"road_v":
				for y in range(item[2], item[3] + 1):
					if not roads.has(Vector2i(item[1], y)):
						place("road", Vector2i(item[1], y), true)
	for b in city.buildings:
		if b.state != "done":
			GameState.finish_building(b)
	for item in plan:
		if str(item[0]).begins_with("road"):
			continue
		var prev := tool
		tool = item[0]
		_reroll_ghost()
		place(item[0], Vector2i(item[1], item[2]), true)
		tool = prev
	for b in city.buildings:
		if b.state != "done":
			GameState.finish_building(b)
			if b.type != "road":
				_name_building(b)
	for v in building_views.values():
		v.refresh_art()
	_update_status()
	_rebuild_poles()
	city.money = 1840
	if GameState.user_args.has("building"):
		for p in [Vector2i(22, 12), Vector2i(10, 12), Vector2i(17, 3)]:
			tool = "house"
			place("house", p, true)
		tool = ""
