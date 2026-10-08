class_name Traffic
extends Node
## Autos und Fußgänger. Alles rechnet in Feldern auf dem Boden.
## Autos fahren rechts, Fußgänger laufen auf dem Gehweg von Haus zu Laden oder Park.

const DIRS := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
const CAR_COLORS := [Pal.BRICK, Pal.TEAL, Pal.OCHRE, Pal.BLUE, Pal.BONE, Pal.MOSS, Pal.PLUM, Pal.STONE_L]
const LANE := 0.17
const WALK := 0.36

var builder: Node
var objects: Node2D
var cars: Array[CarView] = []
var walkers: Array[WalkerView] = []
var _spawn_t := 0.0
var _walk_t := 0.0


func setup(city_builder: Node, objects_node: Node2D) -> void:
	builder = city_builder
	objects = objects_node


func _process(delta: float) -> void:
	var spd: float = builder.speed
	if spd <= 0.0:
		return
	_spawn_t -= delta * spd
	if _spawn_t <= 0.0:
		_spawn_t = randf_range(1.5, 3.0)
		if cars.size() < _target_cars():
			_spawn_car()
	_walk_t -= delta * spd
	if _walk_t <= 0.0:
		_walk_t = randf_range(0.8, 2.2) * (2.5 if builder.night > 0.5 else 1.0)
		if walkers.size() < _target_walkers():
			_spawn_walker()
	for c in cars.duplicate():
		_move_car(c, delta * spd)
	for w in walkers.duplicate():
		_move_walker(w, delta * spd)


func _target_cars() -> int:
	var roads: int = builder.road_count
	var want: int = mini(roads / 3, builder.occupied_houses * 2 + builder.active_work)
	return mini(want, Config.integer("city/max_cars", 22))


func _target_walkers() -> int:
	return mini(builder.occupied_houses * 2, Config.integer("city/max_walkers", 16))


## Rechte Fahrspur in Fahrtrichtung, in Feldern.
static func lane_offset(d: Vector2i) -> Vector2:
	return Vector2(-d.y, d.x) * LANE


static func _center(t: Vector2i) -> Vector2:
	return Vector2(t.x + 0.5, t.y + 0.5)


static func face_of(v: Vector2) -> int:
	if absf(v.x) >= absf(v.y):
		return 0 if v.x > 0 else 2
	return 1 if v.y > 0 else 3


# Autos

func _spawn_car() -> void:
	var start: Vector2i
	var dir: Vector2i
	var entry: Vector2i = builder.entry_tile()
	if randf() < 0.45 and builder.is_road(entry):
		start = entry
		dir = Vector2i(1, 0)
	else:
		var roads: Array = builder.road_tiles()
		if roads.is_empty():
			return
		start = roads[randi() % roads.size()]
		var opts := _exits(start, Vector2i.ZERO)
		if opts.is_empty():
			return
		dir = opts[randi() % opts.size()]
	for c in cars:
		if c.tile == start:
			return
	var car := CarView.new()
	objects.add_child(car)
	car.setup(builder, CAR_COLORS[randi() % CAR_COLORS.size()])
	car.tile = start
	car.dir = dir
	car.gpos = _center(start) + lane_offset(dir)
	car.target = _center(start + dir) + lane_offset(dir)
	car.next_tile = start + dir
	car.face = face_of(Vector2(dir))
	car.sync()
	cars.append(car)


func _exits(t: Vector2i, came: Vector2i) -> Array:
	var out := []
	for d in DIRS:
		if d == -came and came != Vector2i.ZERO:
			continue
		if builder.is_road(t + d):
			out.append(d)
	return out


func _move_car(c: CarView, dt: float) -> void:
	if not builder.is_road(c.next_tile) and not builder.is_road(c.tile):
		_remove_car(c)
		return
	var fwd := Vector2(c.dir)
	var ahead := false
	for o in cars:
		if o == c:
			continue
		var rel: Vector2 = o.gpos - c.gpos
		var along := rel.dot(fwd)
		var side := absf(rel.dot(Vector2(-fwd.y, fwd.x)))
		if along > 0.0 and along < 0.5 and side < 0.14:
			ahead = true
			break
	c.moving = not ahead
	if ahead:
		return
	var step := 0.8 * c.speed_mult * dt
	var to: Vector2 = c.target - c.gpos
	if to.length() <= step:
		c.gpos = c.target
		c.tile = c.next_tile
		if not builder.is_road(c.tile):
			_remove_car(c)
			return
		var opts := _exits(c.tile, c.dir)
		if opts.is_empty():
			opts = [-c.dir]
		var nd: Vector2i = opts[randi() % opts.size()]
		if c.dir in opts and randf() < 0.55:
			nd = c.dir
		c.dir = nd
		c.next_tile = c.tile + nd
		c.target = _center(c.next_tile) + lane_offset(nd)
		if c.next_tile.x < builder.entry_tile().x:
			_remove_car(c)
			return
	else:
		c.gpos += to.normalized() * step
		c.face = face_of(to)
	c.sync()


func _remove_car(c: CarView) -> void:
	cars.erase(c)
	c.queue_free()


func clear_tile(t: Vector2i) -> void:
	for c in cars.duplicate():
		if c.tile == t or c.next_tile == t:
			_remove_car(c)


# Fußgänger

func _spawn_walker() -> void:
	var homes: Array = builder.occupied_house_list()
	if homes.is_empty():
		return
	var home: Dictionary = homes[randi() % homes.size()]
	var goals: Array = builder.walk_goals()
	if goals.size() < 2:
		return
	var goal: Dictionary = goals[randi() % goals.size()]
	if goal == home:
		return
	var a: Vector2i = builder.road_next_to(home)
	var b: Vector2i = builder.road_next_to(goal)
	if a.x < -50 or b.x < -50:
		return
	var path: Array = builder.road_path(a, b)
	if path.is_empty() or path.size() > 24:
		return
	var side := 1.0 if randf() < 0.5 else -1.0
	var pts: Array[Vector2] = []
	pts.append(builder.door_point(home))
	for i in path.size():
		var t: Vector2i = path[i]
		var d: Vector2i = (path[i + 1] - t) if i + 1 < path.size() else (t - path[i - 1] if i > 0 else Vector2i(1, 0))
		pts.append(_center(t) + Vector2(-d.y, d.x) * WALK * side)
	pts.append(builder.door_point(goal))
	var w := WalkerView.new()
	objects.add_child(w)
	w.setup(builder, pts)
	walkers.append(w)


func _move_walker(w: WalkerView, dt: float) -> void:
	if w.done:
		walkers.erase(w)
		w.queue_free()
		return
	w.advance(dt)
