extends Node2D
## Phase 2: Zeitraffer. 50 Jahre in 45 Sekunden. Die Kamera besucht die Gebäude und zieht am Ende zurück.
## Tag und Jahreszeit wechseln in eigener Geschwindigkeit, damit nichts flackert. Das Jahr zählt linear.
## Verfall, Pflanzen, Wasser und Chronik berechnet DecayModel, gezeichnet wird in RuinWorld.

const PLURAL := {"house": "Wohnhäuser", "shop": "Läden", "factory": "Fabriken", "water_tower": "Wassertürme", "power_plant": "Kraftwerke"}

var model: DecayModel
var world: RuinWorld
var camera: Camera2D
var hud: TimelapseHud
var weather: WeatherLayer
var loaded := false
var finished := false
var skipping := false
var t := 0.0
var vt := 0.0
var year := 0.0
var years := 50.0
var duration := 45.0

var _ev_i := 0
var _tour: Array[Vector2] = []
var _center := Vector2.ZERO
var _final_zoom := 0.5
var _frozen := -1.0
var _season_override := -1.0
var _hour_override := -1.0
var _shot_frames := -1
var _shot_path := ""
var _look := Vector3(-1, -1, -1)
var _perf_frames := 0
var _perf_time := 0.0
var _cfg := {}


func _ready() -> void:
	if GameState.city.is_empty():
		if not (GameState.has_save() and GameState.load_game()):
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
			return
	var city: Dictionary = GameState.city
	years = Config.num("phase2/years", 50.0)
	duration = Config.num("phase2/duration_seconds", 45.0)
	_cfg = {"season": Config.num("phase2/season_seconds", 10.0), "day": Config.num("phase2/day_seconds", 3.0),
		"skip": Config.num("phase2/skip_speed", 7.0), "share": Config.num("phase2/tour_share", 0.82)}
	var a := GameState.user_args
	if a.has("year"):
		_frozen = float(a.year)
	if a.has("end"):
		t = duration - 0.02
	if a.has("season"):
		_season_override = float(a.season)
	if a.has("hour"):
		_hour_override = float(a.hour)
	if a.has("look"):
		var lp: PackedStringArray = str(a.look).split(",")
		_look = Vector3(float(lp[0]), float(lp[1]), float(lp[2]) if lp.size() > 2 else 1.0)
	if a.has("shot"):
		_shot_path = str(a.shot)
		_shot_frames = int(a.get("frames", "30"))
	model = DecayModel.new(city)
	world = RuinWorld.new()
	add_child(world)
	world.begin(model)
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	var wl := CanvasLayer.new()
	wl.layer = 2
	add_child(wl)
	weather = WeatherLayer.new()
	wl.add_child(weather)
	var hl := CanvasLayer.new()
	hl.layer = 3
	add_child(hl)
	hud = TimelapseHud.new()
	hl.add_child(hud)
	hud.skip_pressed.connect(_on_skip)
	hud.continue_pressed.connect(_on_continue)
	hud.again_pressed.connect(func(): get_tree().reload_current_scene())
	hud.menu_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	hud.set_events(model.events, years)
	hud.set_year(0.0, years, "Sommer")
	world.set_process(false)
	set_process(true)


func _process(delta: float) -> void:
	if world == null:
		return
	if not loaded:
		var ok := world.step(9.0)
		hud.set_loading(world.progress, world.label)
		if ok:
			_on_loaded()
		return
	vt += delta
	if GameState.user_args.has("perf"):
		_perf_frames += 1
		_perf_time += delta
		if _perf_frames == 300:
			print("PERF Zeitraffer: %.2f ms pro Bild (Leerlauf headless 6.9), %d Gebäude, %d Bäume" % [_perf_time / 300.0 * 1000.0, world.building_views.size(), world.tree_views.size()])
			get_tree().quit()
	world._process(delta)
	if _frozen >= 0.0:
		year = _frozen
		t = duration * year / years
	elif not finished:
		t = minf(duration, t + delta * (float(_cfg.skip) if skipping else 1.0))
		year = years * t / duration
		if t >= duration:
			_finish()
	var cycle: float = _cfg.season
	var sphase := _season_override if _season_override >= 0.0 else DecayModel.season_phase(vt, cycle)
	var hour := _hour_override if _hour_override >= 0.0 else fposmod(7.5 + vt / float(_cfg.day) * 24.0, 24.0)
	world.set_time(year, hour, sphase)
	weather.set_levels(DecayModel.rain(sphase), DecayModel.snow(sphase), DecayModel.leaves(sphase))
	_leaf_fall(delta, sphase)
	_director(clampf(t / duration, 0.0, 1.0))
	hud.set_year(year, years, DecayModel.season_name(sphase))
	while _ev_i < model.events.size() and float(model.events[_ev_i].year) <= year:
		var e: Dictionary = model.events[_ev_i]
		hud.push_event(float(e.year), str(e.text))
		_ev_i += 1
	if _shot_frames >= 0:
		_shot_frames -= 1
		if _shot_frames == 0:
			get_viewport().get_texture().get_image().save_png(_shot_path)
			get_tree().quit()


func _on_loaded() -> void:
	loaded = true
	hud.loaded()
	_make_tour()
	set_process(true)


## Kamerafahrt: von links nach rechts über die auffälligsten Gebäude.
func _make_tour() -> void:
	var c: Dictionary = GameState.city
	_center = Iso.to_screen(float(c.w) * 0.5, float(c.h) * 0.5) + Vector2(0, -10)
	var picks: Array[Vector2] = []
	var seen := {}
	var houses: Array[Vector2] = []
	for v in world.building_views.values():
		var b: Dictionary = v.data
		var h: float = BuildingTypes.info(b.type).get("height", 20)
		var p := Iso.bottom(int(b.x), int(b.y), int(b.w), int(b.h)) + Vector2(0, -h * 0.5)
		if b.type == "house":
			houses.append(p)
		elif b.type != "park" and not seen.has(b.type):
			seen[b.type] = true
			picks.append(p)
	houses.sort_custom(func(a, b): return a.x < b.x)
	if not houses.is_empty():
		picks.append(houses[houses.size() / 2])
	picks.sort_custom(func(a, b): return a.x < b.x)
	if picks.size() < 2:
		picks = [_center + Vector2(-120, 0), _center + Vector2(120, 0)]
	_tour = picks
	var vp := Platform.view_size()
	var fit := minf(vp.x / 1320.0, vp.y / 760.0)
	_final_zoom = 0.5 if fit >= 0.4 else maxf(0.3, fit)
	camera.position = _tour[0].round()


func _director(p: float) -> void:
	if _look.x >= 0.0:
		camera.position = Iso.to_screen(_look.x, _look.y).round()
		camera.zoom = Vector2.ONE * _look.z
		return
	if _tour.is_empty():
		return
	var share: float = _cfg.share
	var pos: Vector2
	var zoom := 1.0
	if p < share:
		var n := _tour.size() - 1
		var f := p / share * float(n)
		var i := mini(int(f), n - 1)
		var e := clampf((f - float(i) - 0.25) / 0.5, 0.0, 1.0)
		e = e * e * (3.0 - 2.0 * e)
		pos = _tour[i].lerp(_tour[i + 1], e)
	else:
		var k := clampf((p - share) / 0.14, 0.0, 1.0)
		k = k * k * (3.0 - 2.0 * k)
		pos = _tour[_tour.size() - 1].lerp(_center, k)
		zoom = lerpf(1.0, _final_zoom, k)
	pos += Vector2(sin(vt * 0.4) * 5.0, cos(vt * 0.33) * 3.0)
	camera.position = pos.round()
	camera.zoom = Vector2.ONE * zoom


## Im Herbst fallen Blätter von den Bäumen in der Welt, dazu kommt das Laub des Bildschirms.
func _leaf_fall(delta: float, sphase: float) -> void:
	var l := DecayModel.leaves(sphase)
	if l <= 0.05 or world.tree_views.is_empty():
		return
	if randf() < delta * 14.0 * l:
		var tv: TreeView = world.tree_views[randi() % world.tree_views.size()]
		if tv.visible and tv.data.kind == "oak":
			var r: float = tv.art.radius
			world.particles.emit("leaf", tv.position + Vector2(randf_range(-r, r) * 0.7, 0), 1,
				{"z": tv.art.height * 0.7, "col": [Pal.OCHRE, Pal.BRICK_L, Pal.RUST, Pal.YELLOW][randi() % 4]})


func _on_skip() -> void:
	if finished:
		return
	if not skipping:
		skipping = true
		hud.set_skip_text("Zum Ende")
	else:
		t = duration


func _finish() -> void:
	finished = true
	year = years
	model.write_back()
	GameState.city.hour = fposmod(7.5, 24.0)
	GameState.save_game()
	hud.show_end(int(years), summary_text())


func _on_continue() -> void:
	GameState.phase = 3
	GameState.save_game()
	GameState.go_to_phase(3)


## Was nach dem Zeitraffer von der Stadt bleibt.
func summary_text() -> String:
	var lines: Array[String] = []
	var s := model.summary(years)
	for type in BuildingTypes.ORDER:
		if not s.has(type):
			continue
		var d: Dictionary = s[type]
		var parts: Array[String] = []
		if int(d.stehend) > 0:
			parts.append("%d stehen" % d.stehend)
		if int(d.dachlos) > 0:
			parts.append("%d ohne Dach" % d.dachlos)
		if int(d.eingestürzt) > 0:
			parts.append("%d eingestürzt" % d.eingestürzt)
		lines.append("%s: %s" % [PLURAL.get(type, type), ", ".join(parts)])
	var trees := 0
	for p in model.plants:
		if model.plant_kind(p, years) != "":
			trees += 1
	lines.append("Die Natur hat %d Bäume und Büsche gepflanzt." % trees)
	var loot := {}
	for b in GameState.city.buildings:
		if b.has("ruin"):
			for item in b.ruin.contents:
				loot[item] = int(loot.get(item, 0)) + int(b.ruin.contents[item])
	var parts2: Array[String] = []
	for item in loot:
		parts2.append("%d %s" % [loot[item], BuildingTypes.ITEM_NAMES.get(item, item)])
	if not parts2.is_empty():
		lines.append("In den Ruinen liegt noch: " + ", ".join(parts2) + ".")
	return "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and loaded and not finished:
		_on_skip()
