extends Node
## Verwaltet Königin, Futter, Brut, Tote, Müll, Einwohnerzahl und den Bauplan des Nests.

const FRUIT_FOOD := 3.0
const MAX_POP := 300
const EGG_TIME := 12.0
const LARVA_TIME := 18.0
const SOLDIER_CHANCE := 0.15

var main
var world
var rng := RandomNumberGenerator.new()

var food := 20.0
var brood: Array = []           # [stufe 0=Ei 1=Larve, zeit, satt, hunger, zellindex]
var corpses := PackedInt32Array()
var surface_corpses: Array = [] # [Vector2, zeit]
var trash_waiting := 0.0
var trash_stored := 0
var buried := 0
var eggs_laid := 0
var delivered := 0
var born := 0
var died := 0
var queen_alive := true
var plan: Array = []            # [PackedInt32Array zellen, kammertyp]
var expansions := 0
var starving := false

var _egg_t := 0.0
var _feed_t := 0.0
var _starve := 0.0
var _kill_t := 0.0
var _jobs_dirty := true
var _job_cells := {}
var _frontier := PackedInt32Array()
var decor_dirty := true


func setup(m) -> void:
	main = m
	world = m.world
	rng.randomize()


# ---------------------------------------------------------------- Neues Spiel

func new_colony() -> void:
	food = 20.0
	brood.clear()
	corpses.clear()
	surface_corpses.clear()
	trash_waiting = 0.0
	trash_stored = 0
	buried = 0
	eggs_laid = 0
	born = 0
	died = 0
	queen_alive = true
	plan.clear()
	expansions = 0
	_starve = 0.0
	var E := World.ENT
	# Startnest: Schacht und Königinnenkammer sind schon gegraben
	var start := _tunnel_cells(Vector2i(E, World.G), Vector2i(E, 52), 0.0)
	for i in start:
		world.cells[i] = World.TUNNEL
	var q := _chamber_cells(Vector2i(E, 54), 6.0, 2.4, World.CH_QUEEN)
	for i in q:
		world.cells[i] = World.TUNNEL
	# Bauplan: jede Stufe ist ein Gang plus Kammer
	_plan_item(Vector2i(E - 4, 54), Vector2i(23, 61), World.CH_BROOD, 6.0, 2.4)
	_plan_item(Vector2i(E + 4, 53), Vector2i(64, 48), World.CH_GRANARY, 6.5, 2.4)
	_plan_item(Vector2i(E + 2, 56), Vector2i(60, 68), World.CH_TRASH, 4.5, 2.0)
	_plan_item(Vector2i(22, 63), Vector2i(11, 76), World.CH_CEMETERY, 5.0, 2.0)
	_plan_item(Vector2i(E, 56), Vector2i(48, 96), World.CH_GRANARY, 6.5, 2.4)
	_plan_item(Vector2i(46, 95), Vector2i(22, 101), World.CH_BROOD, 6.0, 2.4)
	_plan_item(Vector2i(62, 70), Vector2i(74, 86), World.CH_GRANARY, 5.5, 2.2)
	_plan_item(Vector2i(46, 98), Vector2i(30, 128), World.CH_BROOD, 6.0, 2.4)
	_plan_item(Vector2i(50, 98), Vector2i(58, 132), World.CH_GRANARY, 6.0, 2.4)
	_plan_item(Vector2i(60, 134), Vector2i(74, 144), World.CH_CEMETERY, 5.0, 2.0)
	world._reset_runtime()
	world.rebuild_tiles()
	_jobs_dirty = true
	decor_dirty = true


func _plan_item(from: Vector2i, center: Vector2i, ch: int, rx: float, ry: float) -> void:
	var cells := _tunnel_cells(from, center, 0.28)
	cells.append_array(_chamber_cells(center, rx, ry, ch))
	plan.append([cells, ch])


## Gang als zufälliger Weg mit zwei Zellen Breite.
func _tunnel_cells(from: Vector2i, to: Vector2i, wobble: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	var cur := from
	var guard := 0
	while cur != to and guard < 600:
		guard += 1
		_add_cell(out, cur)
		var dx := to.x - cur.x
		var dy := to.y - cur.y
		var step := Vector2i.ZERO
		if rng.randf() < wobble:
			if absi(dx) > absi(dy):
				step = Vector2i(0, 1 if rng.randf() < 0.5 else -1)
			else:
				step = Vector2i(1 if rng.randf() < 0.5 else -1, 0)
		elif rng.randf() * (absi(dx) + absi(dy)) < absi(dx):
			step = Vector2i(signi(dx), 0)
		else:
			step = Vector2i(0, signi(dy))
		cur += step
		cur.x = clampi(cur.x, 2, World.W - 4)
		cur.y = clampi(cur.y, World.G, World.H - 4)
		# zweite Spalte oder Reihe für Breite 2
		if step.y != 0:
			_add_cell(out, cur + Vector2i(1, 0))
		else:
			_add_cell(out, cur + Vector2i(0, 1))
	_add_cell(out, to)
	return out


func _chamber_cells(c: Vector2i, rx: float, ry: float, ch: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for dy in range(-int(ry) - 1, int(ry) + 2):
		for dx in range(-int(rx) - 1, int(rx) + 2):
			var x := c.x + dx
			var y := c.y + dy
			if x < 1 or x > World.W - 2 or y <= World.G or y > World.H - 2:
				continue
			var n := World.hash2(x, y) % 100 / 100.0 * 0.5 - 0.2
			var e := pow(dx / rx, 2) + pow(dy / ry, 2)
			if e <= 1.0 + n:
				var i: int = world.idx(x, y)
				world.chamber[i] = ch
				_add_cell(out, Vector2i(x, y))
	return out


func _add_cell(out: PackedInt32Array, c: Vector2i) -> void:
	if c.x < 1 or c.x > World.W - 2 or c.y < World.G or c.y > World.H - 2:
		return
	var i := c.y * World.W + c.x
	if not out.has(i):
		out.append(i)


# ---------------------------------------------------------------- Grabaufträge

func _refresh_jobs() -> void:
	_jobs_dirty = false
	_job_cells.clear()
	var active := 0
	for item in plan:
		var cells: PackedInt32Array = item[0]
		var left := false
		for i in cells:
			if world.cells[i] == World.SOIL:
				_job_cells[i] = true
				left = true
		if left:
			active += 1
			if active >= 2:
				break
	if active == 0 and _tunnel_count() < 2600 and expansions < 40:
		_plan_expansion()
		if not plan.is_empty():
			for i in plan[-1][0]:
				if world.cells[i] == World.SOIL:
					_job_cells[i] = true
	_frontier.clear()
	var W := World.W
	for i in _job_cells:
		for n in [i - W, i + W, i - 1, i + 1]:
			if n >= 0 and n < W * World.H and world.cells[n] == World.TUNNEL:
				if not _frontier.has(n):
					_frontier.append(n)


func _tunnel_count() -> int:
	return world.cells.count(World.TUNNEL)


func _plan_expansion() -> void:
	expansions += 1
	var ch := World.CH_NONE
	var gran: int = world.chamber_cells[World.CH_GRANARY].size()
	var br: int = world.chamber_cells[World.CH_BROOD].size()
	var cem: int = world.chamber_cells[World.CH_CEMETERY].size()
	if food > gran * 3:
		ch = World.CH_GRANARY
	elif brood.size() > br:
		ch = World.CH_BROOD
	elif buried > cem * 3:
		ch = World.CH_CEMETERY
	elif trash_stored > world.chamber_cells[World.CH_TRASH].size() * 3:
		ch = World.CH_TRASH
	for attempt in 30:
		var c := Vector2i(rng.randi_range(8, World.W - 9), rng.randi_range(World.G + 10, World.H - 6))
		if not _area_free(c, 8, 4):
			continue
		var from: Vector2i = world.nearest_tunnel(c.x, c.y, 40)
		if from.distance_to(c) > 35:
			continue
		if ch == World.CH_NONE:
			plan.append([_tunnel_cells(from, c, 0.35), ch])
		else:
			_plan_item(from, c, ch, 5.5, 2.2)
		return


func _area_free(c: Vector2i, rx: int, ry: int) -> bool:
	for y in range(c.y - ry, c.y + ry + 1):
		for x in range(c.x - rx, c.x + rx + 1):
			if not world.in_grid(x, y) or world.cells[world.idx(x, y)] != World.SOIL:
				return false
	return true


func dig_sources() -> PackedInt32Array:
	if _jobs_dirty:
		_refresh_jobs()
	return _frontier


func has_dig_work() -> bool:
	if _jobs_dirty:
		_refresh_jobs()
	return not _frontier.is_empty()


func dig_target_near(x: int, y: int) -> Vector2i:
	if _jobs_dirty:
		_refresh_jobs()
	for d in [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]:
		var nx: int = x + d.x
		var ny: int = y + d.y
		if world.in_grid(nx, ny):
			var i: int = world.idx(nx, ny)
			if _job_cells.has(i) and world.cells[i] == World.SOIL:
				return Vector2i(nx, ny)
	return World.ARRIVED


func on_dug() -> void:
	_jobs_dirty = true
	world.mark_dirty(World.F_DIG)
	decor_dirty = true


# ---------------------------------------------------------------- Futter

func store_food(amount: float) -> void:
	food += amount
	delivered += 1
	decor_dirty = true


func take_food(amount: float) -> bool:
	if food >= amount:
		food -= amount
		decor_dirty = true
		return true
	return false


# ---------------------------------------------------------------- Brut

func brood_cell() -> int:
	var cells: PackedInt32Array = world.chamber_cells[World.CH_BROOD]
	if cells.is_empty():
		cells = world.chamber_cells[World.CH_QUEEN]
	if cells.is_empty():
		return World.G * World.W + World.ENT
	return cells[rng.randi() % cells.size()]


func larvae_count() -> int:
	var n := 0
	for b in brood:
		if b[0] == 1:
			n += 1
	return n


func hungry_larvae() -> int:
	var n := 0
	for b in brood:
		if b[0] == 1 and b[2] < 0.5:
			n += 1
	return n


func feed_larva() -> void:
	var best := -1
	var low := 99.0
	for k in brood.size():
		if brood[k][0] == 1 and brood[k][2] < low:
			low = brood[k][2]
			best = k
	if best >= 0:
		brood[best][2] = 1.0
		brood[best][3] = 0.0


func brood_cap() -> int:
	return maxi(6, 4 + world.chamber_cells[World.CH_BROOD].size() / 2)


# ---------------------------------------------------------------- Tote und Müll

func add_corpse(x: int, y: int) -> void:
	died += 1
	if y >= World.G and world.is_tunnel(x, y):
		corpses.append(world.idx(x, y))
		world.mark_dirty(World.F_CORPSE)
	else:
		surface_corpses.append([World.cell_center(x, y), 0.0])
	decor_dirty = true


func corpse_sources() -> PackedInt32Array:
	return corpses


func take_corpse_at(x: int, y: int) -> bool:
	var i: int = world.idx(x, y)
	var k := corpses.find(i)
	if k < 0:
		return false
	corpses.remove_at(k)
	world.mark_dirty(World.F_CORPSE)
	decor_dirty = true
	return true


func bury() -> void:
	buried += 1
	decor_dirty = true


func take_trash() -> bool:
	if trash_waiting >= 1.0:
		trash_waiting -= 1.0
		decor_dirty = true
		return true
	return false


func dump_trash() -> void:
	trash_stored += 1
	decor_dirty = true


# ---------------------------------------------------------------- Takt

func tick(dt: float) -> void:
	var pop: int = main.ants.count
	# Brut entwickelt sich
	var k := brood.size() - 1
	while k >= 0:
		var b: Array = brood[k]
		if b[0] == 0:
			b[1] += dt
			if b[1] >= EGG_TIME:
				b[0] = 1
				b[1] = 0.0
				b[2] = 0.6
				decor_dirty = true
		else:
			b[2] = maxf(0.0, b[2] - 0.03 * dt)
			if b[2] > 0.0:
				b[1] += dt
			else:
				b[1] += dt * 0.2
				b[3] += dt
			if b[3] > 50.0:
				var c: int = b[4]
				add_corpse(c % World.W, c / World.W)
				brood.remove_at(k)
			elif b[1] >= LARVA_TIME:
				var c2: int = b[4]
				var soldier := rng.randf() < SOLDIER_CHANCE
				main.ants.spawn(c2 % World.W, c2 / World.W, 1 if soldier else 0)
				born += 1
				brood.remove_at(k)
				decor_dirty = true
		k -= 1
	# Königin legt Eier, wenn genug Futter da ist
	var reserve := 3.0 + pop * 0.4
	if queen_alive and brood.size() < brood_cap() and pop + brood.size() < MAX_POP:
		_egg_t += dt
		var interval := 6.0 - minf(food / 15.0, 3.5)
		if food < reserve:
			# kleine Kolonie: die Königin zehrt von ihren Reserven
			interval = 18.0 if pop <= 4 else 1.0e9
		if _egg_t >= interval:
			_egg_t = 0.0
			food = maxf(0.0, food - 0.6)
			eggs_laid += 1
			brood.append([0, 0.0, 0.0, 0.0, brood_cell()])
			decor_dirty = true
	# Futterverbrauch jede Sekunde
	_feed_t += dt
	if _feed_t >= 1.0:
		_feed_t -= 1.0
		var need := maxf(0, pop - 1) * 0.007 + (0.02 if queen_alive else 0.0)
		if main.events.is_night():
			need *= 0.5   # nachts ruht die Kolonie
		if food >= need:
			food -= need
			trash_waiting += need * 0.08
			_starve = maxf(0.0, _starve - 2.0)
			starving = false
		else:
			food = 0.0
			_starve += 1.0
			starving = _starve > 4.0
		decor_dirty = true
	# Ohne Futter schrumpft die Kolonie
	if _starve > 30.0:
		_kill_t += dt
		if _kill_t > 5.0:
			_kill_t = 0.0
			main.ants.kill_random_worker()
	for sc in surface_corpses:
		sc[1] += dt
	if not surface_corpses.is_empty() and surface_corpses[0][1] > 30.0:
		surface_corpses.pop_front()
		decor_dirty = true
	if _jobs_dirty:
		_refresh_jobs()


# ---------------------------------------------------------------- Infos für das HUD

func chamber_info(ch: int) -> Array:
	var cells: int = world.chamber_cells[ch].size() if ch > 0 else 0
	match ch:
		World.CH_GRANARY:
			return ["KORNKAMMER", ["FUTTER: %d" % int(food), "ABFALL: %d" % int(trash_waiting), "GROESSE: %d" % cells]]
		World.CH_BROOD:
			var eggs := brood.size() - larvae_count()
			return ["BRUTKAMMER", ["EIER: %d" % eggs, "LARVEN: %d" % larvae_count(), "HUNGRIG: %d" % hungry_larvae()]]
		World.CH_QUEEN:
			return ["KÖNIGINNENKAMMER", ["KÖNIGIN: " + ("LEBT" if queen_alive else "TOT"), "EIER GELEGT: %d" % eggs_laid, "GEBOREN: %d" % born]]
		World.CH_CEMETERY:
			return ["FRIEDHOF", ["TOTE: %d" % buried, "NOCH IM NEST: %d" % corpses.size(), "GESTORBEN: %d" % died]]
		World.CH_TRASH:
			return ["MÜLLKAMMER", ["ABFALL: %d" % trash_stored, "WARTET: %d" % int(trash_waiting)]]
	return ["GANG", ["AMEISEN: %d" % main.ants.count]]


# ---------------------------------------------------------------- Speichern

func to_dict() -> Dictionary:
	var p: Array = []
	for item in plan:
		p.append([Marshalls.raw_to_base64(item[0].to_byte_array()), item[1]])
	return {
		"food": food, "brood": brood, "corpses": Array(corpses),
		"trash_waiting": trash_waiting, "trash_stored": trash_stored, "buried": buried,
		"eggs_laid": eggs_laid, "born": born, "died": died, "queen_alive": queen_alive,
		"plan": p, "expansions": expansions, "starve": _starve,
	}


func from_dict(d: Dictionary) -> void:
	food = float(d.get("food", 20.0))
	brood.clear()
	for b in d.get("brood", []):
		brood.append([int(b[0]), float(b[1]), float(b[2]), float(b[3]), int(b[4])])
	corpses.clear()
	for c in d.get("corpses", []):
		corpses.append(int(c))
	surface_corpses.clear()
	trash_waiting = float(d.get("trash_waiting", 0.0))
	trash_stored = int(d.get("trash_stored", 0))
	buried = int(d.get("buried", 0))
	eggs_laid = int(d.get("eggs_laid", 0))
	born = int(d.get("born", 0))
	died = int(d.get("died", 0))
	queen_alive = bool(d.get("queen_alive", true))
	expansions = int(d.get("expansions", 0))
	_starve = float(d.get("starve", 0.0))
	plan.clear()
	for item in d.get("plan", []):
		plan.append([Marshalls.base64_to_raw(item[0]).to_int32_array(), int(item[1])])
	_jobs_dirty = true
	decor_dirty = true
