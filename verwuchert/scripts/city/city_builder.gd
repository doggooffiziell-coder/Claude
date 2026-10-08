class_name CityBuilder
extends Node2D
## Phase 1: Stadtbau. Raster, Bauen, Abreißen, Geld, Bautrupps, Versorgung, Tageszeit.

signal toast(text: String, color: Color)
signal selection_changed(b: Dictionary)
signal payday(net: int)
signal city_finished

const T := 32
const MARGIN := 4
const PAINT_TOOLS := ["house", "shop", "park", "demolish"]
const NO_TILE := Vector2i(-99, -99)

@onready var world: Node2D = $World
@onready var ground: CityRenderer = $World/Ground
@onready var shadow_group: CanvasGroup = $World/Shadows
@onready var shadow_painter: ShadowPainter = $World/Shadows/Painter
@onready var light_pools: LightPools = $World/LightPools
@onready var objects: Node2D = $World/Objects
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
var lamp_views: Array[LampView] = []
var road_count := 0
var occupied_houses := 0
var active_work := 0
var residents := 0
var income_parts := {"steuern": 0, "laeden": 0, "fabriken": 0, "unterhalt": 0}

var _lit_mat: ShaderMaterial
var _status_t := 0.0
var _autosave_t := 0.0
var _dragging := false
var _drag_start := Vector2i.ZERO
var _panning := false
var _pan_moved := 0.0
var _left_pan := false
var _mouse_screen := Vector2(320, 180)
var _last_paint := NO_TILE
var _warned_drag := false
var _hinted_target := false
var _pond: PackedByteArray
var _shot_frames := -1


func _ready() -> void:
	if GameState.city.is_empty():
		GameState.new_game()
	city = GameState.city
	entry_row = int(city.h) / 2
	hour = float(city.hour)
	_pond = Terrain.ponds(int(city.seed), int(city.w), int(city.h), Config.integer("city/pond_count", 1))
	_lit_mat = ShaderMaterial.new()
	_lit_mat.shader = preload("res://shaders/lit.gdshader")
	world.material = _lit_mat
	for n in [objects, particles, top_overlay, sky]:
		n.use_parent_material = true
	ground.setup(self)
	shadow_painter.builder = self
	light_pools.builder = self
	top_overlay.builder = self
	traffic.setup(self, objects)
	var area := Rect2(-MARGIN * T, -MARGIN * T, (int(city.w) + MARGIN * 2) * T, (int(city.h) + MARGIN * 2) * T)
	sky.setup(self, area)
	_ensure_start_roads()
	_spawn_nature()
	_spawn_decor_forest()
	for b in city.buildings:
		_add_view(b)
	_rebuild_lamps()
	_update_status()
	_setup_camera()
	_reroll_ghost()
	$HUD/Root.setup(self)
	if GameState.user_args.has("demo"):
		_demo_city()
	if GameState.user_args.has("hour"):
		hour = float(GameState.user_args.hour)
	if GameState.user_args.has("shot"):
		_shot_frames = int(GameState.user_args.get("frames", "40"))
	if GameState.user_args.has("zoom"):
		camera.zoom = Vector2.ONE * float(GameState.user_args.zoom)
	if GameState.user_args.has("look"):
		var p: PackedStringArray = str(GameState.user_args.look).split(",")
		camera.position = Vector2(float(p[0]) * T, float(p[1]) * T)
		_clamp_camera()
	if GameState.user_args.has("tool"):
		tool = str(GameState.user_args.tool)
		var hp: PackedStringArray = str(GameState.user_args.get("hover", "12,5")).split(",")
		hover = Vector2i(int(hp[0]), int(hp[1]))
	if GameState.user_args.has("select"):
		var sp: PackedStringArray = str(GameState.user_args.select).split(",")
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
	# Bäume auf der Startstraße entfernen
	city.trees = city.trees.filter(func(t): return not (int(t.y) == entry_row and int(t.x) < 3))


func _spawn_nature() -> void:
	for t in city.trees:
		var tv := TreeView.new()
		objects.add_child(tv)
		tv.setup(t, self)
		tree_views.append(tv)


## Dichter Wald im Rand rund um das Baugebiet. Nur Deko, ohne Spielstand.
func _spawn_decor_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(city.seed) + 404
	var w: int = city.w
	var h: int = city.h
	for y in range(-MARGIN, h + MARGIN):
		for x in range(-MARGIN, w + MARGIN):
			if x >= 0 and y >= 0 and x < w and y < h:
				continue
			if y == entry_row and x < 0:
				continue
			var dist: int = maxi(maxi(-x, x - w + 1), maxi(-y, y - h + 1))
			var chance := 0.35 + dist * 0.16
			for k in 2:
				if rng.randf() < chance:
					var kind := "pine" if rng.randf() < 0.45 else "oak"
					if rng.randf() < 0.15:
						kind = "bush"
					var t := {"x": x, "y": y, "kind": kind, "seed": rng.randi() % 9999,
						"ox": rng.randi_range(-12, 12), "oy": rng.randi_range(-10, 8)}
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


func _setup_camera() -> void:
	camera.limit_left = -MARGIN * T + 16
	camera.limit_top = -MARGIN * T + 16
	camera.limit_right = (int(city.w) + MARGIN) * T - 16
	camera.limit_bottom = (int(city.h) + MARGIN) * T + 30
	camera.position = Vector2(int(city.w) * T * 0.5, int(city.h) * T * 0.5 + 8)


# Zeit und Ablauf

func _process(delta: float) -> void:
	anim_time += delta
	var dt := delta * speed
	if speed > 0.0:
		_tick(dt)
	night = DayCycle.night(hour)
	_lit_mat.set_shader_parameter("tint", DayCycle.tint(hour))
	shadow_group.self_modulate = Color(1, 1, 1, 0.36 * DayCycle.sun_strength(hour))
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
	var pd := Config.num("city/payday_seconds", 15.0)
	if float(city.payday_timer) >= pd:
		city.payday_timer = float(city.payday_timer) - pd
		_payday()
	_autosave_t += dt
	if _autosave_t >= Config.num("city/autosave_seconds", 60.0):
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
	for b in city.buildings:
		if b.state == "done":
			continue
		var uses := BuildingTypes.uses_crew(b.type)
		if uses:
			if busy >= crews:
				b.state = "queued"
				continue
			busy += 1
		b.state = "building"
		b.progress = float(b.progress) + dt / BuildingTypes.build_time(b.type)
		if float(b.progress) >= 1.0:
			_complete(b)


func _complete(b: Dictionary) -> void:
	GameState.finish_building(b)
	if b.type == "road":
		_rebuild_lamps()
	else:
		var fp := Rect2(int(b.x) * T, int(b.y) * T, int(b.w) * T, int(b.h) * T)
		particles.emit("spark", Vector2(fp.get_center().x, fp.end.y - 20), 14)
		particles.emit("dust", Vector2(fp.get_center().x, fp.end.y - 4), 10)
		particles.emit("text", Vector2(fp.get_center().x, fp.end.y - BuildingTypes.info(b.type).get("height", 20) - 18), 1, {"text": "Fertig!", "col": Pal.LEAF_L})
	_update_status()


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
		var fp: Rect2 = v.footprint()
		var col := Pal.YELLOW if amount > 0 else Pal.ROSE
		var txt := ("+%d" % amount) if amount > 0 else str(amount)
		particles.emit("text", Vector2(fp.get_center().x, fp.end.y - v.art.size.y - 4), 1, {"text": txt, "col": col})
	city.money = int(city.money) + net
	payday.emit(net)


func set_speed(index: int) -> void:
	var speeds: Array = Config.get_value("city/speeds", [1, 2, 3])
	speed_index = clampi(index, 0, speeds.size())
	speed = 0.0 if speed_index == 0 else float(speeds[speed_index - 1])


func finish_city() -> void:
	tool = ""
	city.hour = hour
	GameState.phase = 2
	GameState.save_game()
	city_finished.emit()
	GameState.go_to_phase(2)


# Versorgung und Einnahmen

func _centers(type: String) -> Array:
	var out := []
	for b in city.buildings:
		if b.type == type and b.state == "done":
			out.append(Vector2(int(b.x) + int(b.w) * 0.5, int(b.y) + int(b.h) * 0.5))
	return out


func _covered(t: Vector2i, type: String) -> bool:
	var rad := float(Config.building(type).get("radius", 6))
	var p := Vector2(t.x + 0.5, t.y + 0.5)
	for c in _centers(type):
		if p.distance_to(c) <= rad:
			return true
	return false


func has_power(t: Vector2i) -> bool:
	return _covered(t, "power_plant")


func has_water(t: Vector2i) -> bool:
	return _covered(t, "water_tower")


func _rect_covered(b: Dictionary, type: String) -> bool:
	for y in int(b.h):
		for x in int(b.w):
			if _covered(Vector2i(int(b.x) + x, int(b.y) + y), type):
				return true
	return false


func touches_road(b: Dictionary) -> bool:
	return road_next_to(b) != NO_TILE


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


func _update_status() -> void:
	road_count = 0
	for t in roads:
		if roads[t].state == "done":
			road_count += 1
	var house_cfg := Config.building("house")
	var shop_cfg := Config.building("shop")
	var fac_cfg := Config.building("factory")
	var park_cfg := Config.building("park")
	occupied_houses = 0
	active_work = 0
	income_parts = {"steuern": 0, "laeden": 0, "fabriken": 0, "unterhalt": 0}
	# Erst Häuser, dann Läden, weil Läden bewohnte Häuser zählen
	for pass_type in ["house", "other"]:
		for v in building_views.values():
			var b: Dictionary = v.data
			if (b.type == "house") != (pass_type == "house"):
				continue
			var st := {"needs": [], "income": 0}
			if b.state != "done":
				v.status = st
				continue
			var road := touches_road(b)
			var power := _rect_covered(b, "power_plant")
			var water := _rect_covered(b, "water_tower")
			st.road = road
			st.power = power
			st.water = water
			match b.type:
				"house":
					if not road: st.needs.append("road_need")
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
				"shop":
					var customers := _count_near(b, "house", float(shop_cfg.get("customer_radius", 6)), "occupied")
					st.customers = customers
					if not road: st.needs.append("road_need")
					if not power: st.needs.append("bolt")
					if road and power and customers == 0: st.needs.append("people_need")
					st.active = road and power and customers > 0
					if st.active:
						active_work += 1
						st.income = mini(int(shop_cfg.get("income", 20)) + customers * int(shop_cfg.get("income_per_house", 5)), int(shop_cfg.get("max_income", 75)))
						income_parts.laeden += st.income
				"factory":
					if not road: st.needs.append("road_need")
					if not power: st.needs.append("bolt")
					st.active = road and power
					if st.active:
						active_work += 1
						st.income = int(fac_cfg.get("income", 90))
						income_parts.fabriken += st.income
				"water_tower", "power_plant":
					st.active = true
					st.income = -int(Config.building(b.type).get("upkeep", 0))
					income_parts.unterhalt += st.income
				"park":
					st.active = true
			v.status = st
	residents = occupied_houses * int(house_cfg.get("residents", 4))


func income_per_payday() -> int:
	return int(income_parts.steuern) + int(income_parts.laeden) + int(income_parts.fabriken) + int(income_parts.unterhalt)


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
	# Vorne zuerst, dort ist die Tür
	for x in range(x0, x0 + w):
		if is_road(Vector2i(x, y0 + h)):
			return Vector2i(x, y0 + h)
	for y in range(y0, y0 + h):
		if is_road(Vector2i(x0 - 1, y)):
			return Vector2i(x0 - 1, y)
		if is_road(Vector2i(x0 + w, y)):
			return Vector2i(x0 + w, y)
	for x in range(x0, x0 + w):
		if is_road(Vector2i(x, y0 - 1)):
			return Vector2i(x, y0 - 1)
	return NO_TILE


func road_path(a: Vector2i, b: Vector2i) -> Array:
	if a == b:
		return [a]
	var prev := {a: a}
	var queue: Array[Vector2i] = [a]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == b:
			break
		for d in Traffic.DIRS:
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


func door_point(b: Dictionary) -> Vector2:
	return Vector2((int(b.x) + int(b.w) * 0.5) * T, (int(b.y) + int(b.h)) * T - 3)


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


func _rebuild_lamps() -> void:
	for lv in lamp_views:
		lv.queue_free()
	lamp_views.clear()
	for t in roads:
		if roads[t].state != "done":
			continue
		if (t.x * 3 + t.y * 5) % 4 != 0:
			continue
		var m := road_mask(t)
		var p := Vector2.ZERO
		if not (m & RoadArt.N):
			p = Vector2(t.x * T + 6, t.y * T + 3)
		elif not (m & RoadArt.S):
			p = Vector2(t.x * T + 24, t.y * T + 31)
		elif not (m & RoadArt.W):
			p = Vector2(t.x * T + 2, t.y * T + 22)
		elif not (m & RoadArt.E):
			p = Vector2(t.x * T + 28, t.y * T + 10)
		else:
			continue
		var lv := LampView.new()
		objects.add_child(lv)
		lv.setup(p, self)
		lamp_views.append(lv)


# Bauen

func select_tool(name: String) -> void:
	tool = name if tool != name else ""
	if tool != "":
		selected = {}
		selection_changed.emit(selected)
	_reroll_ghost()


func _reroll_ghost() -> void:
	ghost_variant = randi() % 10000


func ghost_material() -> String:
	if tool == "" or tool == "demolish":
		return ""
	var rng := RandomNumberGenerator.new()
	rng.seed = ghost_variant
	return BuildingTypes.roll_material(tool, rng)


func inside(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.x < int(city.w) and t.y < int(city.h)


func hover_inside() -> bool:
	return inside(hover)


func hover_valid_tile() -> bool:
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
	city.money = int(city.money) - cost
	_add_view(b)
	var fp := Rect2(t.x * T, t.y * T, size.x * T, size.y * T)
	particles.emit("dust", Vector2(fp.get_center().x, fp.end.y - 6), 6 if type != "road" else 3)
	if type != "road":
		particles.emit("text", Vector2(fp.get_center().x, fp.position.y - 4), 1, {"text": "-%d" % cost, "col": Pal.ROSE, "life": 1.0})
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
		particles.emit("text", Vector2(last.x * T + 16, last.y * T), 1, {"text": "-%d" % spent, "col": Pal.ROSE, "life": 1.0})


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
	if b.type == "road" and Vector2i(int(b.x), int(b.y)).y == entry_row and int(b.x) == 0:
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
	var fp := Rect2(int(b.x) * T, int(b.y) * T, int(b.w) * T, int(b.h) * T)
	if b.type == "road":
		roads.erase(Vector2i(int(b.x), int(b.y)))
		_rebuild_lamps()
	else:
		var v: Node = building_views.get(int(b.id))
		if v:
			v.queue_free()
		building_views.erase(int(b.id))
	for i in 3:
		particles.emit("dust", Vector2(fp.get_center().x + randf_range(-10, 10), fp.end.y - randf_range(2, 20)), 6)
	particles.emit("smoke", Vector2(fp.get_center().x, fp.end.y - 10), 4, {"size": 1.6, "dark": false})
	particles.emit("text", Vector2(fp.get_center().x, fp.position.y), 1, {"text": "+%d" % refund, "col": Pal.YELLOW, "life": 1.0})
	if selected == b:
		selected = {}
		selection_changed.emit(selected)
	GameState.remove_building(b)
	_update_status()


# Eingabe

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_mouse_screen = event.position
	if event is InputEventMouseMotion:
		_update_hover()
		if _panning or _left_pan:
			var d: Vector2 = event.relative / camera.zoom
			camera.position -= d
			_pan_moved += d.length()
			_clamp_camera()
		elif _dragging and tool in PAINT_TOOLS and hover != _last_paint:
			_last_paint = hover
			if tool == "demolish":
				demolish(hover)
			elif can_place(tool, hover):
				place(tool, hover, true)
	elif event is InputEventMouseButton:
		_update_hover()
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_left_down()
				else:
					_left_up()
			MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				if event.pressed:
					_panning = true
					_pan_moved = 0.0
				else:
					_panning = false
					if event.button_index == MOUSE_BUTTON_RIGHT and _pan_moved < 4.0:
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
		return true
	if not selected.is_empty():
		selected = {}
		selection_changed.emit(selected)
		return true
	return false


func _left_down() -> void:
	_warned_drag = false
	if tool == "":
		# Ohne Werkzeug: Ziehen bewegt die Karte, ein Klick wählt ein Gebäude
		_left_pan = true
		_pan_moved = 0.0
		return
	if not hover_inside():
		return
	_dragging = true
	_last_paint = hover
	match tool:
		"road":
			_drag_start = hover
		"demolish":
			demolish(hover)
		_:
			place(tool, hover)


func _left_up() -> void:
	if _left_pan:
		_left_pan = false
		if _pan_moved < 4.0:
			var b := building_at(hover)
			selected = {} if (b.is_empty() or b.type == "road") else b
			selection_changed.emit(selected)
		return
	if _dragging and tool == "road":
		place_road_path(_l_path(_drag_start, hover))
	_dragging = false


func mouse_world() -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * _mouse_screen


func _update_hover() -> void:
	var p := mouse_world()
	var size := BuildingTypes.size_of(tool) if tool in BuildingTypes.INFO else Vector2i.ONE
	# Große Gebäude: Maus liegt in der Mitte der Fläche
	var off := Vector2((size.x - 1) * T * 0.5, (size.y - 1) * T * 0.5)
	hover = Vector2i(floor((p.x - off.x) / T), floor((p.y - off.y) / T))
	if not _dragging and tool == "road":
		_drag_start = hover


func _camera_keys(delta: float) -> void:
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): v.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): v.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): v.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): v.y += 1
	if v != Vector2.ZERO:
		camera.position += v.normalized() * 220.0 * delta / camera.zoom.x
		_clamp_camera()
		_update_hover()


func _clamp_camera() -> void:
	var half := get_viewport_rect().size * 0.5 / camera.zoom
	camera.position.x = clampf(camera.position.x, camera.limit_left + half.x, camera.limit_right - half.x)
	camera.position.y = clampf(camera.position.y, camera.limit_top + half.y, camera.limit_bottom - half.y)


func set_zoom(z: int) -> void:
	var before := mouse_world()
	camera.zoom = Vector2(z, z)
	camera.force_update_scroll()
	var after := mouse_world()
	camera.position += before - after
	_clamp_camera()


# Beispielstadt für Tests und Screenshots

func _demo_city() -> void:
	city.money = 99999
	var plan := [
		["road_h", 3, 8, 20], ["road_v", 6, 3, 14], ["road_v", 14, 3, 14], ["road_v", 20, 4, 13],
		["road_h", 6, 3, 15], ["road_h", 6, 13, 15], ["road_h", 14, 11, 7],
		["power_plant", 1, 10], ["water_tower", 10, 9],
		["house", 7, 7], ["house", 8, 7], ["house", 9, 7], ["house", 11, 7], ["house", 12, 7],
		["house", 7, 9], ["house", 8, 9], ["house", 12, 9], ["house", 13, 9],
		["house", 7, 2], ["house", 8, 2], ["house", 10, 2], ["house", 12, 2],
		["shop", 15, 7], ["shop", 16, 7], ["park", 10, 7], ["park", 15, 9], ["power_plant", 16, 4],
		["factory", 17, 9], ["house", 15, 2], ["house", 16, 2], ["shop", 18, 7],
		["park", 11, 9], ["house", 7, 12], ["house", 8, 12], ["house", 9, 12], ["house", 12, 12], ["house", 13, 12],
		["house", 21, 6], ["house", 21, 7], ["shop", 21, 9], ["park", 22, 9],
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
			_:
				_reroll_ghost()
				var prev := tool
				tool = item[0]
				place(item[0], Vector2i(item[1], item[2]), true)
				tool = prev
	for b in city.buildings:
		if b.state != "done":
			GameState.finish_building(b)
	_rebuild_lamps()
	_update_status()
	city.money = 1840
	if GameState.user_args.has("building"):
		# Ein paar Baustellen zeigen
		for p in [Vector2i(22, 12), Vector2i(10, 12), Vector2i(17, 3)]:
			tool = "house"
			place("house", p, true)
		tool = ""
