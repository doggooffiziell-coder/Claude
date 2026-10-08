class_name MenuDiorama
extends Node2D
## Die kleine Stadt auf der schwebenden Insel im Hauptmenü.
## Sie nutzt die echten Spielklassen (Gebäude, Bäume, Masten, Autos, Fußgänger, Schatten, Licht),
## darum sieht sie genauso aus wie die Stadt im Spiel. Der Tag läuft schnell durch.
## Diese Klasse spielt für die Spielklassen die Rolle des CityBuilder:
## speed, anim_time, night, hour, particles, building_views, tree_views, pole_views, traffic.

const W := 6
const H := 6
const NO_TILE := Vector2i(-99, -99)
const LANE := 0.17
const WALK := 0.36
const DIRS := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
const CAR_COLORS := [Pal.BRICK, Pal.TEAL, Pal.OCHRE, Pal.BLUE, Pal.BONE, Pal.MOSS, Pal.PLUM]

## [Typ, x, y, Tür, Variante, Material]
const PLAN := [
	["factory", 0, 0, "left", 11, "ziegel"],
	["power_plant", 4, 0, "left", 5, "beton"],
	["park", 2, 0, "left", 3, ""],
	["house", 2, 1, "right", 11, "ziegel"],
	["house", 0, 2, "left", 8, "holz"],
	["house", 1, 2, "left", 2, "ziegel"],
	["house", 2, 2, "left", 19, "holz"],
	["shop", 4, 2, "left", 5, "ziegel"],
	["house", 5, 2, "left", 21, "ziegel"],
	["water_tower", 1, 4, "left", 7, "stahl"],
	["house", 2, 4, "right", 33, "holz"],
	["house", 2, 5, "right", 14, "ziegel"],
	["park", 4, 4, "left", 4, ""],
]
## [Art, x, y, ox, oy]
const TREES := [
	["oak", 0, 4, -4, 2], ["pine", 4, 5, 6, -2], ["oak", 5, 4, 0, 4], ["bush", 5, 5, 2, 2],
	["pine", 5, 1, 4, 6], ["bush", 0, 3, 0, 0],
]
const POND := [Vector2i(0, 5), Vector2i(1, 5)]

## Oberer Eckpunkt der Insel auf dem Bildschirm.
var base := Vector2(440, 62)
## Tiefe der Erdkante und Länge der Gesteinsspitze. Auf kurzen Bildern werden beide kleiner.
var cliff := 34
var taper := 46
var speed := 1.0
var anim_time := 0.0
var night := 0.0
var hour := 17.4
var hour_rate := 24.0 / 90.0
var particles: Particles
var building_views := {}
var tree_views: Array[TreeView] = []
var pole_views: Array[PoleView] = []
var cars: Array[CarView] = []
var walkers: Array[WalkerView] = []
var traffic := {"cars": []}
var roads := {}
## Wie im Spiel: die Leitungen zeichnen sich neu, wenn diese Zahl wechselt.
var pole_version := 1

var _objects: Node2D
var _shadow_group: CanvasGroup
var _lit_mat: ShaderMaterial
var _ground: ImageTexture
var _bits: Array
var _under: Dictionary
var _car_t := 1.0
var _walk_t := 2.0
var _sparkles: Array[Vector3] = []


func _ready() -> void:
	for i in W:
		roads[Vector2i(i, 3)] = true
	for j in H:
		roads[Vector2i(3, j)] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var pond := PackedByteArray()
	pond.resize(W * H)
	for t in POND:
		pond[t.y * W + t.x] = 1
		for k in 7:
			_sparkles.append(Vector3(t.x * 32 + rng.randi_range(8, 24), t.y * 32 + rng.randi_range(8, 24), rng.randf() * TAU))
	var img := NatureArt.ground_image(4242, W, H, 0, pond)
	_ground = ImageTexture.create_from_image(img)
	configure(get_viewport().get_visible_rect().size)

	_lit_mat = ShaderMaterial.new()
	_lit_mat.shader = preload("res://shaders/lit.gdshader")
	material = _lit_mat

	_shadow_group = CanvasGroup.new()
	_shadow_group.fit_margin = 0.0
	_shadow_group.clear_margin = 0.0
	add_child(_shadow_group)
	var sp := ShadowPainter.new()
	sp.builder = self
	_shadow_group.add_child(sp)

	var pools := LightPools.new()
	pools.builder = self
	add_child(pools)

	_objects = Node2D.new()
	_objects.y_sort_enabled = true
	_objects.use_parent_material = true
	add_child(_objects)

	var wires := WireLayer.new()
	wires.builder = self
	wires.use_parent_material = true
	add_child(wires)

	particles = Particles.new()
	particles.use_parent_material = true
	add_child(particles)

	_build_town()
	hour = float(GameState.user_args.get("hour", hour))


## Passt die Insel an die Größe des Bildes an. Das Handy hat ein breiteres, aber kürzeres Bild.
func configure(vp: Vector2) -> void:
	var tiny := vp.y < 300.0
	var compact := vp.y < 340.0
	var new_cliff := 26 if compact else 34
	var new_taper := 0 if tiny else (18 if compact else 46)
	base = Vector2(clampf(vp.x - 205.0, 350.0, 470.0), 40.0 if tiny else (56.0 if compact else 62.0))
	if not _under.is_empty() and new_cliff == cliff and new_taper == taper:
		return
	cliff = new_cliff
	taper = new_taper
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	_bits = IsoCliff.make_bits(rng, cliff)
	_under = IsoCliff.underside(W, H, cliff, taper, 4242) if taper > 0 else {"tex": null, "pos": Vector2.ZERO}


# Aufbau

func _build_town() -> void:
	var id := 1
	for item in PLAN:
		var size := BuildingTypes.size_of(item[0])
		var b := {"id": id, "type": item[0], "x": item[1], "y": item[2], "w": size.x, "h": size.y,
			"material": item[5], "variant": item[4], "state": "done", "progress": 1.0,
			"condition": 100, "contents": {}, "facing": item[3]}
		id += 1
		var v := BuildingView.new()
		_objects.add_child(v)
		v.setup(b, self)
		v.status = {"occupied": true, "active": true, "needs": []}
		building_views[int(b.id)] = v
	for t in TREES:
		var d := {"x": t[1], "y": t[2], "kind": t[0], "seed": t[1] * 7 + t[2] * 3 + 1, "ox": t[3], "oy": t[4]}
		var tv := TreeView.new()
		_objects.add_child(tv)
		tv.setup(d, self, true)
		tree_views.append(tv)
	for t in roads:
		if (t.x + t.y) % 2 != 0:
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
		_objects.add_child(pv)
		pv.setup(g, t, self)
		pole_views.append(pv)


## Straßen reichen über den Rand hinaus, darum haben die Endstücke keine Kappe.
func _is_road(t: Vector2i) -> bool:
	if roads.has(t):
		return true
	return (t.y == 3 and (t.x == -1 or t.x == W)) or (t.x == 3 and (t.y == -1 or t.y == H))


func road_mask(t: Vector2i) -> int:
	var m := 0
	if _is_road(t + Vector2i(0, -1)): m |= RoadArt.N
	if _is_road(t + Vector2i(1, 0)): m |= RoadArt.E
	if _is_road(t + Vector2i(0, 1)): m |= RoadArt.S
	if _is_road(t + Vector2i(-1, 0)): m |= RoadArt.W
	return m


## Bodenpunkt vor der Tür in Feldern.
func door_point(b: Dictionary) -> Vector2:
	var x0 := float(b.x)
	var y0 := float(b.y)
	var w := float(b.w)
	var h := float(b.h)
	if str(b.get("facing", "left")) == "right":
		return Vector2(x0 + w + 0.02, y0 + h * 0.5)
	return Vector2(x0 + w * 0.5, y0 + h + 0.02)


# Ablauf

func _process(delta: float) -> void:
	anim_time += delta
	hour = fposmod(hour + delta * hour_rate, 24.0)
	night = DayCycle.night(hour)
	_lit_mat.set_shader_parameter("tint", DayCycle.tint(hour))
	_shadow_group.visible = Settings.shadows
	_shadow_group.self_modulate = Color(1, 1, 1, 0.34 * DayCycle.sun_strength(hour))
	# Die Insel schwebt in ganzen Pixeln
	position = Vector2(base.x, roundf(base.y + sin(anim_time * 0.8) * 2.0))
	_car_t -= delta
	if _car_t <= 0.0:
		_car_t = randf_range(2.2, 4.2)
		if cars.size() < 4:
			_spawn_car()
	_walk_t -= delta
	if _walk_t <= 0.0:
		_walk_t = randf_range(3.0, 6.0) * (2.0 if night > 0.5 else 1.0)
		if walkers.size() < 4:
			_spawn_walker()
	for c in cars.duplicate():
		_move_car(c, delta)
	for w in walkers.duplicate():
		_move_walker(w, delta)
	queue_redraw()


func _draw() -> void:
	var u: Dictionary = _under
	if u.tex != null:
		draw_texture(u.tex, u.pos)
	IsoCliff.draw(self, W, H, 0, _bits, cliff)
	draw_set_transform_matrix(Iso.GROUND)
	draw_texture(_ground, Vector2.ZERO)
	for s in _sparkles:
		var v := sin(anim_time * 1.3 + s.z)
		if v > 0.86:
			draw_rect(Rect2(s.x, s.y, 1, 1), Pal.WHITE if v > 0.95 else Pal.SKY)
	for t in roads:
		var tex := SpriteFactory.road(road_mask(t), (t.x * 7 + t.y * 13) % 6)
		draw_texture(tex, Vector2(t.x * 32, t.y * 32))
	draw_set_transform_matrix(Transform2D.IDENTITY)


# Autos

func _center(t: Vector2i) -> Vector2:
	return Vector2(t.x + 0.5, t.y + 0.5)


func _exits(t: Vector2i, came: Vector2i) -> Array:
	var out := []
	for d in DIRS:
		if d == -came:
			continue
		if roads.has(t + d):
			out.append(d)
	return out


func _spawn_car() -> void:
	var entries := [
		[Vector2i(0, 3), Vector2i(1, 0)], [Vector2i(5, 3), Vector2i(-1, 0)],
		[Vector2i(3, 0), Vector2i(0, 1)], [Vector2i(3, 5), Vector2i(0, -1)],
	]
	var e: Array = entries[randi() % entries.size()]
	for c in cars:
		if c.tile == e[0]:
			return
	var car := CarView.new()
	_objects.add_child(car)
	car.setup(self, CAR_COLORS[randi() % CAR_COLORS.size()])
	var dir: Vector2i = e[1]
	car.tile = e[0]
	car.dir = dir
	car.gpos = _center(car.tile) + Vector2(-dir.y, dir.x) * LANE - Vector2(dir) * 0.5
	car.target = _center(car.tile) + Vector2(-dir.y, dir.x) * LANE
	car.next_tile = car.tile
	car.face = Traffic.face_of(Vector2(dir))
	car.modulate.a = 0.0
	car.sync()
	cars.append(car)
	traffic.cars = cars


func _move_car(c: CarView, dt: float) -> void:
	var fwd := Vector2(c.dir)
	var ahead := false
	for o in cars:
		if o == c:
			continue
		var rel: Vector2 = o.gpos - c.gpos
		if rel.dot(fwd) > 0.0 and rel.dot(fwd) < 0.5 and absf(rel.dot(Vector2(-fwd.y, fwd.x))) < 0.14:
			ahead = true
			break
	c.moving = not ahead
	if ahead:
		return
	var step := 0.8 * c.speed_mult * dt
	var to: Vector2 = c.target - c.gpos
	# Blendet am Inselrand ein und aus
	var leaving := not roads.has(c.next_tile) and c.next_tile != c.tile
	if leaving:
		c.modulate.a = clampf((to.length() - 0.5) / 0.35, 0.0, 1.0)
	else:
		c.modulate.a = minf(1.0, c.modulate.a + dt * 3.0)
	if to.length() <= step:
		c.gpos = c.target
		c.tile = c.next_tile if roads.has(c.next_tile) else c.tile
		if not roads.has(c.next_tile) and c.next_tile != c.tile:
			_remove_car(c)
			return
		var opts := _exits(c.tile, c.dir)
		var nd: Vector2i = c.dir
		if not opts.is_empty():
			nd = opts[randi() % opts.size()]
			if c.dir in opts and randf() < 0.6:
				nd = c.dir
		c.dir = nd
		c.next_tile = c.tile + nd
		c.target = _center(c.next_tile) + Vector2(-nd.y, nd.x) * LANE
		c.face = Traffic.face_of(Vector2(nd))
	else:
		c.gpos += to.normalized() * step
		c.face = Traffic.face_of(to)
	c.sync()


func _remove_car(c: CarView) -> void:
	cars.erase(c)
	traffic.cars = cars
	c.queue_free()


# Fußgänger

func _road_next_to(b: Dictionary) -> Vector2i:
	var x0 := int(b.x)
	var y0 := int(b.y)
	var w := int(b.w)
	var h := int(b.h)
	var cands: Array[Vector2i] = []
	for x in range(x0, x0 + w):
		cands.append(Vector2i(x, y0 + h))
		cands.append(Vector2i(x, y0 - 1))
	for y in range(y0, y0 + h):
		cands.append(Vector2i(x0 + w, y))
		cands.append(Vector2i(x0 - 1, y))
	for t in cands:
		if roads.has(t):
			return t
	return NO_TILE


func _road_path(a: Vector2i, b: Vector2i) -> Array:
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
			if not prev.has(n) and roads.has(n):
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


func _spawn_walker() -> void:
	var homes: Array = []
	var goals: Array = []
	for v in building_views.values():
		var b: Dictionary = v.data
		if b.type == "house":
			homes.append(b)
		if b.type in ["shop", "park", "house"]:
			goals.append(b)
	var home: Dictionary = homes[randi() % homes.size()]
	var goal: Dictionary = goals[randi() % goals.size()]
	if goal == home:
		return
	var a := _road_next_to(home)
	var bb := _road_next_to(goal)
	if a == NO_TILE or bb == NO_TILE:
		return
	var path := _road_path(a, bb)
	if path.is_empty() or path.size() > 12:
		return
	var side := 1.0 if randf() < 0.5 else -1.0
	var pts: Array[Vector2] = [door_point(home)]
	for i in path.size():
		var t: Vector2i = path[i]
		var d: Vector2i = (path[i + 1] - t) if i + 1 < path.size() else (t - path[i - 1] if i > 0 else Vector2i(1, 0))
		pts.append(_center(t) + Vector2(-d.y, d.x) * WALK * side)
	pts.append(door_point(goal))
	var w := WalkerView.new()
	_objects.add_child(w)
	w.setup(self, pts)
	walkers.append(w)


func _move_walker(w: WalkerView, dt: float) -> void:
	if w.done:
		walkers.erase(w)
		w.queue_free()
		return
	w.advance(dt)
