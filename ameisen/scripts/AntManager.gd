extends Node2D
## Zentrale Ameisenlogik: alle Daten liegen in Arrays (Position, Zustand, Ziel ...).
## Gezeichnet wird über ein einziges MultiMeshInstance2D.

const MAX := 320
const FRAME_W := 8
const FRAME_H := 6
const FRAMES := 14
const SPEED := [10.0, 11.0, 3.0]     # Arbeiterin, Soldat, Königin in Pixel pro Sekunde

var main
var world
var colony
var phero
var events
var rng := RandomNumberGenerator.new()
var count := 0

# Position in Pixeln
var px := PackedFloat32Array()
var py := PackedFloat32Array()
# aktuelle Zelle und Ziel-Zelle
var cx := PackedInt32Array()
var cy := PackedInt32Array()
var tx := PackedInt32Array()
var ty := PackedInt32Array()
# Zustand
var state := PackedInt32Array()
var phase := PackedInt32Array()
var role := PackedInt32Array()
var carry := PackedInt32Array()
var face := PackedInt32Array()
var dir := PackedInt32Array()
var gx := PackedInt32Array()
var gy := PackedInt32Array()
var tk := PackedInt32Array()
var age := PackedFloat32Array()
var max_age := PackedFloat32Array()
var hp := PackedFloat32Array()
var timer := PackedFloat32Array()
var wt := PackedFloat32Array()
var trail := PackedFloat32Array()
var anim := PackedFloat32Array()

var _kills := {}
var _assign_t := 0.0
var _mm: MultiMesh
@onready var _mmi: MultiMeshInstance2D = $MultiMeshInstance2D


func setup(m) -> void:
	main = m
	world = m.world
	colony = m.colony
	phero = m.phero
	events = m.events
	rng.randomize()
	px.resize(MAX)
	py.resize(MAX)
	age.resize(MAX)
	max_age.resize(MAX)
	hp.resize(MAX)
	timer.resize(MAX)
	wt.resize(MAX)
	trail.resize(MAX)
	anim.resize(MAX)
	cx.resize(MAX)
	cy.resize(MAX)
	tx.resize(MAX)
	ty.resize(MAX)
	state.resize(MAX)
	phase.resize(MAX)
	role.resize(MAX)
	carry.resize(MAX)
	face.resize(MAX)
	dir.resize(MAX)
	gx.resize(MAX)
	gy.resize(MAX)
	tk.resize(MAX)
	_build_multimesh()


func clear() -> void:
	count = 0
	_kills.clear()
	_mm.visible_instance_count = 0


# ================================================================ Anlegen und Entfernen

func spawn(x: int, y: int, r: int, start_age := 0.0) -> int:
	if count >= MAX:
		return -1
	var i := count
	count += 1
	var p := World.cell_center(x, y)
	px[i] = p.x
	py[i] = p.y
	cx[i] = x
	cy[i] = y
	tx[i] = x
	ty[i] = y
	role[i] = r
	state[i] = Ant.S_QUEEN if r == Ant.R_QUEEN else (Ant.S_SOLDIER if r == Ant.R_SOLDIER else Ant.S_IDLE)
	phase[i] = 0
	carry[i] = Ant.C_NONE
	face[i] = 0
	dir[i] = 1
	gx[i] = x
	gy[i] = y
	tk[i] = x
	age[i] = start_age
	max_age[i] = 1.0e9 if r == Ant.R_QUEEN else rng.randf_range(300.0, 600.0)
	hp[i] = 3.0 if r == Ant.R_QUEEN else (1.5 if r == Ant.R_SOLDIER else 1.0)
	timer[i] = rng.randf_range(0.0, 0.6)
	wt[i] = 0.0
	trail[i] = 0.0
	anim[i] = rng.randf() * 4.0
	return i


## Ameise zum Entfernen vormerken. Entfernt wird am Ende des Takts.
func request_kill(i: int, leave_corpse: bool) -> void:
	if i >= 0 and i < count:
		_kills[i] = leave_corpse


func kill_random_worker() -> void:
	if count <= 1:
		return
	for tries in 10:
		var i := rng.randi() % count
		if role[i] != Ant.R_QUEEN:
			request_kill(i, true)
			return


func _process_kills() -> void:
	if _kills.is_empty():
		return
	var idxs: Array = _kills.keys()
	idxs.sort()
	idxs.reverse()
	for i in idxs:
		if i >= count:
			continue
		if _kills[i]:
			colony.add_corpse(cx[i], cy[i])
		else:
			colony.died += 1
		if role[i] == Ant.R_QUEEN:
			colony.queen_alive = false
			main.hud.banner("DIE KÖNIGIN IST TOT", 6.0)
		_remove(i)
	_kills.clear()


func _remove(i: int) -> void:
	var j := count - 1
	if i != j:
		px[i] = px[j]
		py[i] = py[j]
		cx[i] = cx[j]
		cy[i] = cy[j]
		tx[i] = tx[j]
		ty[i] = ty[j]
		state[i] = state[j]
		phase[i] = phase[j]
		role[i] = role[j]
		carry[i] = carry[j]
		face[i] = face[j]
		dir[i] = dir[j]
		gx[i] = gx[j]
		gy[i] = gy[j]
		tk[i] = tk[j]
		age[i] = age[j]
		max_age[i] = max_age[j]
		hp[i] = hp[j]
		timer[i] = timer[j]
		wt[i] = wt[j]
		trail[i] = trail[j]
		anim[i] = anim[j]
	count -= 1


func set_state(i: int, s: int) -> void:
	state[i] = s
	phase[i] = 0
	wt[i] = 0.0
	trail[i] = 0.0


func count_role(r: int) -> int:
	var n := 0
	for i in count:
		if role[i] == r:
			n += 1
	return n


func count_state(s: int) -> int:
	var n := 0
	for i in count:
		if state[i] == s:
			n += 1
	return n


# ================================================================ Takt

func tick(dt: float) -> void:
	var T := float(World.T)
	var wet: bool = world.wet
	for i in count:
		age[i] += dt
		wt[i] += dt
		if age[i] > max_age[i]:
			request_kill(i, true)
			continue
		# Wasser in tiefen Gängen ertränkt Ameisen
		if wet and world.water_at(cx[i], cy[i]) > 0.55:
			hp[i] -= dt * (0.05 if role[i] == Ant.R_QUEEN else 0.7)
			if hp[i] <= 0.0:
				request_kill(i, true)
				continue
		if timer[i] > 0.0:
			timer[i] -= dt
			anim[i] += dt * 0.5
			continue
		var gxp := tx[i] * T + 1.5
		var gyp := ty[i] * T + 1.5
		var dx := gxp - px[i]
		var dy := gyp - py[i]
		var dist := sqrt(dx * dx + dy * dy)
		var sp: float = SPEED[role[i]]
		if carry[i] != Ant.C_NONE:
			sp *= 0.8
		var step := sp * dt
		if dist <= step:
			px[i] = gxp
			py[i] = gyp
			cx[i] = tx[i]
			cy[i] = ty[i]
			Ant.think(self, i)
		else:
			px[i] += dx / dist * step
			py[i] += dy / dist * step
			anim[i] += dt * sp * 0.35
	_process_kills()
	_assign_t += dt
	if _assign_t > 0.7:
		_assign_t = 0.0
		_assign_jobs()


## Freie Arbeiterinnen bekommen die Aufgabe, die gerade am meisten fehlt.
func _assign_jobs() -> void:
	var counts := [0, 0, 0, 0, 0, 0, 0, 0]
	var idle: Array[int] = []
	var workers := 0
	for i in count:
		counts[state[i]] += 1
		if role[i] == Ant.R_WORKER:
			workers += 1
			if state[i] == Ant.S_IDLE and timer[i] <= 0.0 and cy[i] >= World.G:
				idle.append(i)
	if idle.is_empty():
		return
	idle.shuffle()
	var want_dig := clampi(2 + workers / 8, 2, 16) if colony.has_dig_work() else 0
	var larvae: int = colony.larvae_count()
	var want_nurse := 0
	if larvae > 0:
		want_nurse = clampi(ceili(larvae / 3.0), 1, 14)
	elif not colony.brood.is_empty() and workers > 8:
		want_nurse = 1
	var want_under := 0
	if not colony.corpses.is_empty() or colony.trash_waiting >= 1.0:
		want_under = clampi(1 + colony.corpses.size() / 3, 1, 6)
	var want_forage := maxi(2, ceili(workers * 0.6))
	var go_out: bool = not events.is_night() and not events.raining
	for i in idle:
		var s := -1
		if counts[Ant.S_NURSE] < want_nurse:
			s = Ant.S_NURSE
		elif counts[Ant.S_UNDERTAKE] < want_under:
			s = Ant.S_UNDERTAKE
		elif counts[Ant.S_DIG] < want_dig:
			s = Ant.S_DIG
		elif go_out and counts[Ant.S_FORAGE] + counts[Ant.S_CARRY] < want_forage:
			s = Ant.S_FORAGE
		if s < 0:
			continue
		counts[s] += 1
		counts[Ant.S_IDLE] -= 1
		set_state(i, s)


# ================================================================ Zeichnen

func render() -> void:
	var T := float(World.T)
	for i in count:
		var dxs := tx[i] - cx[i]
		var dys := ty[i] - cy[i]
		var f := face[i]
		if dxs > 0:
			f = 0
		elif dxs < 0:
			f = 1
		elif dys < 0:
			f = 2
		elif dys > 0:
			f = 3
		face[i] = f
		var pos := Vector2(px[i], py[i])
		if pos.y < World.G * T and pos.y > World.SURF * T - 1.0:
			pos.y -= world.surface_offset(int(pos.x / T))
		var xf: Transform2D
		match f:
			0:
				xf = Transform2D(0.0, Vector2.ONE, 0.0, pos)
			1:
				xf = Transform2D(0.0, Vector2(-1, 1), 0.0, pos)
			2:
				xf = Transform2D(-PI * 0.5, Vector2.ONE, 0.0, pos)
			_:
				xf = Transform2D(PI * 0.5, Vector2.ONE, 0.0, pos)
		_mm.set_instance_transform_2d(i, xf)
		var fr := 0
		match role[i]:
			Ant.R_SOLDIER:
				fr = 2
			Ant.R_QUEEN:
				fr = 4
			_:
				if carry[i] != Ant.C_NONE:
					fr = 4 + carry[i] * 2
		fr += int(anim[i] * 2.0) & 1
		_mm.set_instance_custom_data(i, Color(fr, 0, 0, 0))
	_mm.visible_instance_count = count


func _build_multimesh() -> void:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var hw := FRAME_W * 0.5
	var hh := FRAME_H * 0.5
	arrays[Mesh.ARRAY_VERTEX] = PackedVector2Array([Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_2D
	_mm.use_custom_data = true
	_mm.mesh = mesh
	_mm.instance_count = MAX
	_mm.visible_instance_count = 0
	_mmi.multimesh = _mm
	_mmi.texture = _build_atlas()
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float frames = 14.0;
void vertex() {
	UV.x = (UV.x + INSTANCE_CUSTOM.r) / frames;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("frames", float(FRAMES))
	_mmi.material = mat


# Ameisen-Sprites als Pixel-Muster, Blick nach rechts
const WORKER := [
	["........", "......#.", ".+#.#.##", "#######.", ".#.#.#..", "........"],
	["........", ".......#", ".+#.#.##", "#######.", "#.#.#.#.", "........"],
]
const SOLDIER := [
	["........", ".....##.", ".+#.####", "########", ".#.#.#..", "........"],
	["........", ".....##.", ".+#.####", "#######.", "#.#.#.##", "........"],
]
const QUEEN := [
	[".....y.y", ".....yyy", "+##.#.##", "#######.", "###.#.#.", ".#......"],
	[".....y.y", ".....yyy", "+##.#.##", "#######.", "###..#.#", "..#.#..."],
]
const ITEM_COLORS := [Color(0, 0, 0), Color(0.88, 0.2, 0.15), Color(0.86, 0.74, 0.5), Color(0.25, 0.22, 0.2), Color(0.6, 0.47, 0.3)]


func _build_atlas() -> ImageTexture:
	var img := Image.create(FRAME_W * FRAMES, FRAME_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for a in 2:
		_paint(img, a, WORKER[a], Color.TRANSPARENT)
		_paint(img, 2 + a, SOLDIER[a], Color.TRANSPARENT)
		_paint(img, 4 + a, QUEEN[a], Color.TRANSPARENT)
		for c in range(1, 5):
			_paint(img, 4 + c * 2 + a, WORKER[a], ITEM_COLORS[c])
	return ImageTexture.create_from_image(img)


func _paint(img: Image, frame: int, rows: Array, item: Color) -> void:
	var body := Color(0.11, 0.06, 0.05)
	var shine := Color(0.36, 0.2, 0.14)
	var crown := Color(0.98, 0.82, 0.2)
	for y in FRAME_H:
		var row: String = rows[y]
		for x in FRAME_W:
			var ch := row[x]
			var col := Color.TRANSPARENT
			if ch == "#":
				col = body
			elif ch == "+":
				col = shine
			elif ch == "y":
				col = crown
			if col.a > 0.0:
				img.set_pixel(frame * FRAME_W + x, y, col)
	if item.a > 0.0:
		# Last über dem Kopf
		for y in 2:
			for x in range(4, 7):
				img.set_pixel(frame * FRAME_W + x, y, item if (x + y) % 3 != 0 else item.lightened(0.25))


# ================================================================ Speichern

func to_dict() -> Dictionary:
	var list: Array = []
	for i in count:
		list.append([cx[i], cy[i], role[i], snappedf(age[i], 0.1), snappedf(max_age[i], 0.1)])
	return {"ants": list}


func from_dict(d: Dictionary) -> void:
	clear()
	for a in d.get("ants", []):
		var x := int(a[0])
		var y := int(a[1])
		if not world.in_grid(x, y):
			continue
		var i := spawn(x, y, int(a[2]), float(a[3]))
		if i >= 0:
			max_age[i] = float(a[4])
