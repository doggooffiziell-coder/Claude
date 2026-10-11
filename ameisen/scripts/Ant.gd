class_name Ant
extends RefCounted
## Zustandsmaschine für eine einzelne Ameise.
## Die Daten liegen zentral in den Arrays von AntManager. Ant.think(m, i) entscheidet
## für Ameise i den nächsten Schritt, sobald sie ihr aktuelles Ziel erreicht hat.

enum { S_IDLE, S_DIG, S_FORAGE, S_CARRY, S_NURSE, S_UNDERTAKE, S_SOLDIER, S_QUEEN }
enum { R_WORKER, R_SOLDIER, R_QUEEN }
enum { C_NONE, C_FOOD, C_DIRT, C_CORPSE, C_TRASH }

const STATE_NAMES := ["RUHT", "GRÄBT", "SUCHT FUTTER", "TRÄGT FUTTER", "PFLEGT BRUT", "TRÄGT TOTE", "SOLDAT", "KÖNIGIN"]


static func think(m, i: int) -> void:
	match m.state[i]:
		S_IDLE:
			_idle(m, i)
		S_DIG:
			_dig(m, i)
		S_FORAGE:
			_forage(m, i)
		S_CARRY:
			_carry(m, i)
		S_NURSE:
			_nurse(m, i)
		S_UNDERTAKE:
			_undertake(m, i)
		S_SOLDIER:
			_soldier(m, i)
		S_QUEEN:
			_queen(m, i)


# ================================================================ Bewegungshelfer

static func _go(m, i: int, x: int, y: int) -> void:
	m.tx[i] = x
	m.ty[i] = y


static func _wait(m, i: int, t: float) -> void:
	m.tx[i] = m.cx[i]
	m.ty[i] = m.cy[i]
	m.timer[i] = t


static func _wander(m, i: int, only_chamber := -1) -> void:
	var n: Vector2i = m.world.random_neighbor(m.cx[i], m.cy[i], m.rng, only_chamber)
	if n.x == m.cx[i] and n.y == m.cy[i]:
		_wait(m, i, 0.5)
	else:
		_go(m, i, n.x, n.y)


## Oberirdisch zurück zum Eingang und hinab. Liefert true, solange die Ameise oben ist.
static func _head_home(m, i: int) -> bool:
	var x: int = m.cx[i]
	var y: int = m.cy[i]
	if y >= World.G:
		return false
	if y < World.SURF:
		# im Baum oder Busch: erst zum Stamm, dann hinunter
		if x != m.tk[i]:
			_go(m, i, x + signi(m.tk[i] - x), y)
		else:
			_go(m, i, x, y + 1)
		return true
	if x != World.ENT:
		_go(m, i, x + signi(World.ENT - x), y)
	else:
		_go(m, i, x, World.G)
	return true


## Einem Wegfeld durch die Tunnel folgen. 0 = unterwegs, 1 = angekommen, 2 = kein Weg.
static func _travel(m, i: int, fid: int) -> int:
	if _head_home(m, i):
		return 0
	var x: int = m.cx[i]
	var y: int = m.cy[i]
	if not m.world.is_tunnel(x, y):
		# steckt im Erdreich, etwa ein Soldat nach dem Kampf
		var t: Vector2i = m.world.nearest_tunnel(x, y)
		if t.x != x:
			_go(m, i, x + signi(t.x - x), y)
		else:
			_go(m, i, x, y + signi(t.y - y))
		return 0
	var s: Vector2i = m.world.next_step(fid, x, y, m.rng)
	if s == World.ARRIVED:
		return 1
	if s == World.NO_PATH:
		return 2
	_go(m, i, s.x, s.y)
	return 0


static func _pick(m, fids: Array) -> int:
	for f in fids:
		if m.world.has_field(f):
			return f
	return World.F_EXIT


## Zur Oberfläche gehen. Liefert true, sobald die Ameise oben steht.
static func _go_surface(m, i: int) -> bool:
	if m.cy[i] < World.G:
		return true
	var r := _travel(m, i, World.F_EXIT)
	if r == 1:
		_go(m, i, World.ENT, World.SURF)
	elif r == 2:
		_wander(m, i)
	return false


# ================================================================ Zustände

static func _idle(m, i: int) -> void:
	if _head_home(m, i):
		return
	if not m.world.is_tunnel(m.cx[i], m.cy[i]):
		_travel(m, i, World.F_EXIT)
		return
	if m.world.has_field(World.F_QUEEN) and m.world.field_value(World.F_QUEEN, m.cx[i], m.cy[i]) > 22:
		if _travel(m, i, World.F_QUEEN) == 0:
			return
	if m.rng.randf() < 0.4:
		_wait(m, i, m.rng.randf_range(0.5, 2.0))
	else:
		_wander(m, i)


static func _dig(m, i: int) -> void:
	match m.phase[i]:
		0:
			# zur Grabstelle
			var r := _travel(m, i, World.F_DIG)
			if r == 2:
				if m.carry[i] == C_DIRT:
					m.phase[i] = 2
					_dig(m, i)
					return
				m.set_state(i, S_IDLE)
				_wait(m, i, 0.3)
			elif r == 1:
				var t: Vector2i = m.colony.dig_target_near(m.cx[i], m.cy[i])
				if t == World.ARRIVED:
					m.world.mark_dirty(World.F_DIG)
					_wait(m, i, 0.4)
					return
				m.gx[i] = t.x
				m.gy[i] = t.y
				m.phase[i] = 1
				m.face[i] = 0 if t.x > m.cx[i] else (1 if t.x < m.cx[i] else (2 if t.y < m.cy[i] else 3))
				_wait(m, i, m.world.dig_time(t.y))
		1:
			# Zelle ausgraben, Aushub aufnehmen
			if m.world.cell(m.gx[i], m.gy[i]) == World.SOIL:
				m.world.dig(m.gx[i], m.gy[i])
				m.colony.on_dug()
				m.carry[i] = C_DIRT
				m.trail[i] += 1.0
			# erst mit voller Ladung nach oben
			if m.carry[i] == C_DIRT and (m.trail[i] >= 3.0 or not m.colony.has_dig_work()):
				m.phase[i] = 2
				_dig(m, i)
			else:
				m.phase[i] = 0
				_wait(m, i, 0.1)
		2:
			# Aushub nach oben bringen
			if _go_surface(m, i):
				m.phase[i] = 3
				var side := -1 if m.rng.randf() < 0.5 else 1
				m.gx[i] = clampi(World.ENT + side * m.rng.randi_range(2, 11), 2, World.W - 3)
				_dig(m, i)
		3:
			var x: int = m.cx[i]
			if x != m.gx[i]:
				_go(m, i, x + signi(m.gx[i] - x), World.SURF)
			else:
				for k in int(maxf(1.0, m.trail[i])):
					m.world.add_dirt(x + k % 2)
				m.trail[i] = 0.0
				m.carry[i] = C_NONE
				m.phase[i] = 4
				_wait(m, i, 0.3)
		4:
			if not _head_home(m, i):
				m.phase[i] = 0
				_dig(m, i)


static func _forage(m, i: int) -> void:
	var ev = m.events
	if m.phase[i] <= 1 and (ev.is_night() or ev.raining):
		m.set_state(i, S_IDLE)
		_idle(m, i)
		return
	match m.phase[i]:
		0:
			if _go_surface(m, i):
				m.phase[i] = 1
				m.wt[i] = 0.0
				m.dir[i] = -1 if m.rng.randf() < 0.5 else 1
				# Gedächtnis: zurück zur letzten ergiebigen Quelle
				var mem: int = m.world.source_at(m.tk[i])
				if mem >= 0 and m.tk[i] != m.cx[i] and m.world.has_fruit(mem) and m.rng.randf() < 0.75:
					m.dir[i] = signi(m.tk[i] - m.cx[i])
					m.trail[i] = -float(absi(m.tk[i] - m.cx[i]))
				_forage(m, i)
		1:
			# auf der Oberfläche suchen und Duftspuren folgen
			if m.wt[i] > 50.0:
				m.set_state(i, S_IDLE)
				_idle(m, i)
				return
			var x: int = m.cx[i]
			var si: int = m.world.source_at(x)
			if si >= 0:
				if m.world.has_fruit(si) and m.rng.randf() < 0.85:
					var f: Vector2i = m.world.pick_fruit(si, m.rng)
					m.tk[i] = x
					m.gx[i] = f.x
					m.gy[i] = f.y
					m.phase[i] = 2
					_forage(m, i)
					return
				if not m.world.has_fruit(si):
					m.trail[i] = -10.0   # leere Quelle: Duft eine Weile ignorieren
			if m.trail[i] < 0.0:
				m.trail[i] += 1.0
			else:
				# Spur in der Nähe? Dann dem Anstieg folgen: der Duft ist nahe am Futter am stärksten.
				var far: Vector2 = m.phero.sense(x, World.SURF, 6)
				if far.x + far.y > 0.08:
					var near: Vector2 = m.phero.sense(x, World.SURF, 2)
					if near.x > near.y * 1.02:
						m.dir[i] = -1
					elif near.y > near.x * 1.02:
						m.dir[i] = 1
					if m.rng.randf() < 0.01:
						m.dir[i] = -m.dir[i]
				elif m.rng.randf() < 0.05:
					m.dir[i] = -m.dir[i]
			var nx: int = x + m.dir[i]
			if nx < 1 or nx > World.W - 2:
				m.dir[i] = -m.dir[i]
				nx = x + m.dir[i]
			_go(m, i, nx, World.SURF)
		2:
			# den Stamm hoch und am Ast entlang zur Frucht
			var x: int = m.cx[i]
			var y: int = m.cy[i]
			if x == m.gx[i] and y == m.gy[i]:
				if m.world.take_fruit(x, y):
					m.carry[i] = C_FOOD
					m.set_state(i, S_CARRY)
					m.trail[i] = 1.0
					_carry(m, i)
				else:
					m.phase[i] = 3
					_forage(m, i)
			elif y > m.gy[i] and x == m.tk[i]:
				_go(m, i, x, y - 1)
			elif y == m.gy[i]:
				_go(m, i, x + signi(m.gx[i] - x), y)
			else:
				m.phase[i] = 3
				_forage(m, i)
		3:
			# ohne Beute wieder hinunter
			var x: int = m.cx[i]
			var y: int = m.cy[i]
			if y < World.SURF:
				if x != m.tk[i]:
					_go(m, i, x + signi(m.tk[i] - x), y)
				else:
					_go(m, i, x, y + 1)
			else:
				m.phase[i] = 1
				_forage(m, i)


static func _carry(m, i: int) -> void:
	match m.phase[i]:
		0:
			# oben: zum Eingang und dabei eine Duftspur legen
			if m.cy[i] < World.G:
				m.phero.deposit(m.cx[i], m.cy[i], m.trail[i])
				m.trail[i] = maxf(0.25, m.trail[i] * 0.975)
				_head_home(m, i)
				return
			m.phase[i] = 1
			_carry(m, i)
		1:
			var fid := _pick(m, [World.F_GRANARY, World.F_QUEEN])
			var r := _travel(m, i, fid)
			if r != 0:
				m.colony.store_food(m.colony.FRUIT_FOOD)
				m.carry[i] = C_NONE
				m.set_state(i, S_IDLE)
				_wait(m, i, 0.5)


static func _nurse(m, i: int) -> void:
	match m.phase[i]:
		0:
			if m.colony.brood.is_empty():
				m.set_state(i, S_IDLE)
				_idle(m, i)
				return
			var r := _travel(m, i, _pick(m, [World.F_GRANARY, World.F_QUEEN]))
			if r != 0:
				if m.colony.take_food(0.3):
					m.carry[i] = C_FOOD
				m.phase[i] = 1
				_wait(m, i, 0.4)
		1:
			var r := _travel(m, i, _pick(m, [World.F_BROOD, World.F_QUEEN]))
			if r != 0:
				if m.carry[i] == C_FOOD:
					m.colony.feed_larva()
					m.carry[i] = C_NONE
				m.phase[i] = 2
				m.wt[i] = 0.0
				_wait(m, i, 0.6)
		2:
			# Brut pflegen: in der Kammer umhergehen
			if m.wt[i] > 7.0:
				if m.colony.hungry_larvae() > 0:
					m.phase[i] = 0
					_nurse(m, i)
				else:
					m.set_state(i, S_IDLE)
					_wait(m, i, 0.5)
				return
			var ch: int = m.world.chamber_at(m.cx[i], m.cy[i])
			if m.rng.randf() < 0.4:
				_wait(m, i, m.rng.randf_range(0.4, 1.2))
			else:
				_wander(m, i, ch if ch != 0 else -1)


static func _undertake(m, i: int) -> void:
	match m.phase[i]:
		0:
			if not m.colony.corpses.is_empty():
				var r := _travel(m, i, World.F_CORPSE)
				if r == 1:
					if m.colony.take_corpse_at(m.cx[i], m.cy[i]):
						m.carry[i] = C_CORPSE
						m.phase[i] = 1
						_wait(m, i, 0.4)
					else:
						_wait(m, i, 0.2)
				elif r == 2:
					m.phase[i] = 3 if m.colony.trash_waiting >= 1.0 else 0
					if m.phase[i] == 0:
						m.set_state(i, S_IDLE)
					_wait(m, i, 0.3)
			elif m.colony.trash_waiting >= 1.0:
				m.phase[i] = 3
				_undertake(m, i)
			else:
				m.set_state(i, S_IDLE)
				_idle(m, i)
		1:
			# Tote zum Friedhof
			var r := _travel(m, i, _pick(m, [World.F_CEMETERY, World.F_TRASH, World.F_EXIT]))
			if r != 0:
				m.colony.bury()
				m.carry[i] = C_NONE
				m.set_state(i, S_IDLE)
				_wait(m, i, 0.4)
		3:
			var r := _travel(m, i, _pick(m, [World.F_GRANARY, World.F_QUEEN]))
			if r != 0:
				if m.colony.take_trash():
					m.carry[i] = C_TRASH
					m.phase[i] = 4
					_wait(m, i, 0.3)
				else:
					m.set_state(i, S_IDLE)
					_wait(m, i, 0.3)
		4:
			# Abfall in die Müllkammer
			var r := _travel(m, i, _pick(m, [World.F_TRASH, World.F_CEMETERY, World.F_EXIT]))
			if r != 0:
				m.colony.dump_trash()
				m.carry[i] = C_NONE
				m.set_state(i, S_IDLE)
				_wait(m, i, 0.4)


static func _soldier(m, i: int) -> void:
	var ev = m.events
	if ev.cent_active and not ev.cent_fleeing:
		var head: Vector2 = ev.cent_head
		var p := Vector2(m.px[i], m.py[i])
		if p.distance_to(head) < 90.0 and head.y > World.G * World.T:
			# Angriff: direkt auf den Kopf zu, notfalls durch die Erde
			var hx := int(head.x / World.T)
			var hy := int(head.y / World.T)
			var x: int = m.cx[i]
			var y: int = m.cy[i]
			if absi(hx - x) <= 1 and absi(hy - y) <= 1:
				_wait(m, i, 0.25)
			elif absi(hx - x) > absi(hy - y):
				_go(m, i, x + signi(hx - x), y)
			else:
				_go(m, i, x, maxi(World.G, y + signi(hy - y)))
			return
	if _head_home(m, i):
		return
	if m.world.has_field(World.F_QUEEN) and m.world.field_value(World.F_QUEEN, m.cx[i], m.cy[i]) > 16:
		if _travel(m, i, World.F_QUEEN) == 0:
			return
	if not m.world.is_tunnel(m.cx[i], m.cy[i]):
		_travel(m, i, World.F_EXIT)
		return
	if m.rng.randf() < 0.5:
		_wait(m, i, m.rng.randf_range(0.5, 2.5))
	else:
		_wander(m, i)


static func _queen(m, i: int) -> void:
	var x: int = m.cx[i]
	var y: int = m.cy[i]
	if m.world.chamber_at(x, y) != World.CH_QUEEN and m.world.has_field(World.F_QUEEN):
		if _travel(m, i, World.F_QUEEN) == 0:
			return
	if m.rng.randf() < 0.6:
		_wait(m, i, m.rng.randf_range(1.0, 3.0))
	else:
		_wander(m, i, World.CH_QUEEN)
