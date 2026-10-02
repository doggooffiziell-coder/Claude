class_name Doll
extends Node2D
## Verlet ragdoll with joint angle limits, wounds, bleeding, severing
## and a small set of vital signs.

enum { HEAD, TORSO, PELVIS, UARM_L, LARM_L, UARM_R, LARM_R, THIGH_L, SHIN_L, FOOT_L, THIGH_R, SHIN_R, FOOT_R }
enum { P_HEAD, P_NECK, P_WAIST, P_HIP, P_ELBOW_L, P_HAND_L, P_ELBOW_R, P_HAND_R, P_KNEE_L, P_ANKLE_L, P_TOE_L, P_KNEE_R, P_ANKLE_R, P_TOE_R }

const PART_COUNT := 13
const PART_A := [P_NECK, P_NECK, P_WAIST, P_NECK, P_ELBOW_L, P_NECK, P_ELBOW_R, P_HIP, P_KNEE_L, P_ANKLE_L, P_HIP, P_KNEE_R, P_ANKLE_R]
const PART_B := [P_HEAD, P_WAIST, P_HIP, P_ELBOW_L, P_HAND_L, P_ELBOW_R, P_HAND_R, P_KNEE_L, P_ANKLE_L, P_TOE_L, P_KNEE_R, P_ANKLE_R, P_TOE_R]
const PARENT := [TORSO, -1, TORSO, TORSO, UARM_L, TORSO, UARM_R, PELVIS, THIGH_L, SHIN_L, PELVIS, THIGH_R, SHIN_R]
const WIDTH := [2.0, 6.0, 5.0, 3.0, 3.0, 3.0, 3.0, 4.0, 3.0, 2.0, 4.0, 3.0, 2.0]
const FAR_SIDE := [false, false, false, true, true, false, false, true, true, true, false, false, false]
const DRAW_ORDER := [UARM_L, LARM_L, THIGH_L, SHIN_L, FOOT_L, PELVIS, TORSO, HEAD, THIGH_R, SHIN_R, FOOT_R, UARM_R, LARM_R]
const POINT_OWNER := [HEAD, TORSO, TORSO, PELVIS, UARM_L, LARM_L, UARM_R, LARM_R, THIGH_L, SHIN_L, FOOT_L, THIGH_R, SHIN_R, FOOT_R]
const POINT_INV_MASS := [0.8, 0.6, 0.5, 0.6, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

## Standing pose, facing right. Origin sits on the floor between the feet.
const POSE := [
	Vector2(0, -37), Vector2(0, -32), Vector2(0, -22), Vector2(0, -18),
	Vector2(-1, -25), Vector2(0, -18), Vector2(1, -25), Vector2(2, -18),
	Vector2(-1, -10), Vector2(-1, -2), Vector2(2, -1),
	Vector2(1, -10), Vector2(1, -2), Vector2(4, -1),
]

## Joint limits: child part, parent part, joint sits on parent end A, min and max degrees.
## Angles are measured between the parent vector (other end to joint) and the child vector.
const JOINTS := [
	[HEAD, TORSO, true, -35.0, 35.0],
	[PELVIS, TORSO, false, -35.0, 45.0],
	[UARM_L, TORSO, true, 30.0, 330.0],
	[UARM_R, TORSO, true, 30.0, 330.0],
	[LARM_L, UARM_L, false, -150.0, 0.0],
	[LARM_R, UARM_R, false, -150.0, 0.0],
	[THIGH_L, PELVIS, false, -120.0, 30.0],
	[THIGH_R, PELVIS, false, -120.0, 30.0],
	[SHIN_L, THIGH_L, false, -10.0, 150.0],
	[SHIN_R, THIGH_R, false, -10.0, 150.0],
	[FOOT_L, SHIN_L, false, -140.0, -30.0],
	[FOOT_R, SHIN_R, false, -140.0, -30.0],
]

const GRAVITY := 420.0
const ITERATIONS := 8
const HEAD_R := 4.0
const MAX_STEP := 14.0
const WOUND_SPEED := 210.0
const SEVER_SPEED := 520.0
const MAX_WOUNDS := 32
const OUT_BL := 35.0
const AGONY_PN := 65.0

const COL_SKIN := Color("f2f2ec")
const COL_SKIN_FAR := Color("cdcdc6")
const COL_LINE := Color("0c0c0e")
const COL_CHAR := Color("342c28")
const COL_ICE := Color("a0d2f5")
const COL_WOUND := Color("b01020")
const COL_SCAR := Color("5a1418")
const COL_STUMP := Color("d01828")


class Joint:
	var child: int
	var parent: int
	var at_a: bool
	var center: float
	var half: float
	var rest := 0.0
	var frozen_rel := 0.0
	var active := true


class Wound:
	var part: int
	var t: float
	var s: float
	var bleed: float
	var size: int
	var stump := false


var world: World
var doll_id := 1

var pos := PackedVector2Array()
var prev := PackedVector2Array()
var inv_mass := PackedFloat32Array()
var owner_part := PackedInt32Array()
var impact_cd := PackedFloat32Array()
var pa := PackedInt32Array()
var pb := PackedInt32Array()
var rest_len := PackedFloat32Array()
var severed: Array[bool] = []
var char_lvl := PackedFloat32Array()
var blade_cd := PackedFloat32Array()
var joints: Array[Joint] = []
var wounds: Array[Wound] = []

var grabbed := -1
var grab_target := Vector2.ZERO
var _grab_inv := 1.0

# Vitals, all 0..100 except hr in beats per minute.
var ko := 100.0
var bl := 100.0
var pn := 0.0
var o2 := 100.0
var hr := 72.0
var dead := false
var head_under := false
var burn_timer := 0.0
var blade_timer := 0.0
var freeze := 0.0
var frozen := false
var since_damage := 0.0
var healing := false
var beat_phase := 0.0
var beat_flash := 0.0
var hurt_flash := 0.0
var _no_air := 0.0
var _sever_cd := 0.0
var _wound_cd := 0.0
var _burn_immune := 0.0
var _standing := false
var _beat := false


func setup(w: World, base: Vector2, id: int) -> void:
	world = w
	doll_id = id
	for i in POSE.size():
		var p: Vector2 = base + POSE[i]
		pos.append(p)
		prev.append(p)
		inv_mass.append(POINT_INV_MASS[i])
		owner_part.append(POINT_OWNER[i])
		impact_cd.append(0.0)
	for k in PART_COUNT:
		pa.append(PART_A[k])
		pb.append(PART_B[k])
		rest_len.append(pos[pa[k]].distance_to(pos[pb[k]]))
		severed.append(false)
		char_lvl.append(0.0)
		blade_cd.append(0.0)
	for d in JOINTS:
		var j := Joint.new()
		j.child = d[0]
		j.parent = d[1]
		j.at_a = d[2]
		j.center = deg_to_rad((d[3] + d[4]) * 0.5)
		j.half = deg_to_rad((d[4] - d[3]) * 0.5)
		j.rest = _joint_rel(j)
		joints.append(j)


# ---------------------------------------------------------------- physics

func step(dt: float) -> void:
	var gstep := GRAVITY * dt * dt
	var feet_x0 := PackedFloat32Array([pos[P_ANKLE_L].x, pos[P_TOE_L].x, pos[P_ANKLE_R].x, pos[P_TOE_R].x])
	for i in pos.size():
		impact_cd[i] = maxf(0.0, impact_cd[i] - dt)
		if i == grabbed:
			_move_grabbed(i)
			continue
		var p := pos[i]
		var v := p - prev[i]
		var in_liquid := world.is_liquid_at(p)
		if in_liquid:
			v *= 0.86
			v.y += gstep * 0.12
			if v.length() > 2.5:
				world.splash(p, v / dt)
		else:
			v *= 0.998
			# Static friction: slow points resting on the ground settle down.
			if v.length_squared() < 0.25:
				v *= 0.6 if world.is_solid_at(p + Vector2(0, 1.2)) else 0.9
			v.y += gstep
		v = v.limit_length(MAX_STEP)
		_integrate(i, v, dt)

	_balance(gstep)
	for it in ITERATIONS:
		for k in PART_COUNT:
			_solve_distance(pa[k], pb[k], rest_len[k])
		_solve_joints()
		if it % 2 == 1:
			for i in pos.size():
				_push_out(i)
	# Standing feet grip the floor instead of sliding.
	if _standing:
		var feet_ids := [P_ANKLE_L, P_TOE_L, P_ANKLE_R, P_TOE_R]
		for n in 4:
			var i: int = feet_ids[n]
			if is_attached(owner_part[i]):
				pos[i].x = feet_x0[n]
				prev[i].x = feet_x0[n]

	_update_effects(dt)
	_update_vitals(dt)
	queue_redraw()


## A conscious doll with its feet on the floor keeps its upper body over its feet.
func _balance(gstep: float) -> void:
	_standing = false
	if dead or frozen or grabbed >= 0 or is_out() or pn > 90.0:
		return
	if not is_attached(PELVIS) or not (is_attached(SHIN_L) or is_attached(SHIN_R)):
		return
	var grounded := false
	var feet_x := 0.0
	var feet := 0
	for k in [FOOT_L, FOOT_R]:
		if not is_attached(k):
			continue
		var ankle := pos[pa[k]]
		feet_x += ankle.x
		feet += 1
		if world.is_solid_at(ankle + Vector2(0, 2.5)) or world.is_solid_at(pos[pb[k]] + Vector2(0, 2.5)):
			grounded = true
	if not grounded or feet == 0:
		return
	feet_x /= feet
	var neck := pos[P_NECK]
	var hip := pos[P_HIP]
	var ground_y := maxf(pos[P_ANKLE_L].y, pos[P_ANKLE_R].y) + 2.0
	if neck.y > hip.y - 7.0 or hip.y > ground_y - 10.0 or absf(neck.x - feet_x) > 9.0:
		return
	_standing = true
	# Pull every attached body point toward the standing pose above the feet.
	var s := 0.15 * clampf(ko / 100.0, 0.0, 1.0)
	var base := Vector2(feet_x, ground_y)
	for i in POSE.size():
		if i == P_ANKLE_L or i == P_ANKLE_R or i == P_TOE_L or i == P_TOE_R:
			continue
		if not is_attached(owner_part[i]):
			continue
		var target: Vector2 = base + POSE[i]
		var v := (pos[i] - prev[i]) * 0.7
		pos[i] += (target - pos[i]) * s
		prev[i] = pos[i] - v


func _move_grabbed(i: int) -> void:
	var old := pos[i]
	var target := grab_target
	var d := target - old
	if d.length() > MAX_STEP:
		target = old + d.limit_length(MAX_STEP)
	if world.is_solid_at(target):
		target = old
	prev[i] = old
	pos[i] = target


## Moves one point pixel by pixel and resolves hits with solid cells per axis.
func _integrate(i: int, v: Vector2, dt: float) -> void:
	var p := pos[i]
	var steps := maxi(1, int(ceilf(maxf(absf(v.x), absf(v.y)))))
	var sv := v / steps
	var hit := 0.0
	for _s in steps:
		if sv.x != 0.0:
			var nx := p.x + sv.x
			if world.is_solid_at(Vector2(nx, p.y)):
				hit = maxf(hit, absf(v.x))
				v.x *= -0.25
				sv.x = 0.0
			else:
				p.x = nx
		if sv.y != 0.0:
			var ny := p.y + sv.y
			if world.is_solid_at(Vector2(p.x, ny)):
				hit = maxf(hit, absf(v.y))
				if v.y > 0.0:
					v.x *= 0.6
				v.y *= -0.2
				sv.y = 0.0
			else:
				p.y = ny
	pos[i] = p
	prev[i] = p - v
	var speed := hit / dt
	if speed > WOUND_SPEED * 0.75 and impact_cd[i] <= 0.0:
		impact_cd[i] = 0.15
		_on_impact(i, speed)


func _solve_distance(a: int, b: int, rest: float) -> void:
	var d := pos[b] - pos[a]
	var len := d.length()
	if len < 0.0001:
		return
	var wa := 0.0 if a == grabbed else inv_mass[a]
	var wb := 0.0 if b == grabbed else inv_mass[b]
	var ws := wa + wb
	if ws <= 0.0:
		return
	var corr := d * ((len - rest) / len)
	pos[a] += corr * (wa / ws)
	pos[b] -= corr * (wb / ws)


func _joint_points(j: Joint) -> Array:
	var joint_pt := pa[j.parent] if j.at_a else pb[j.parent]
	var other_pt := pb[j.parent] if j.at_a else pa[j.parent]
	return [joint_pt, other_pt, pb[j.child]]


func _joint_rel(j: Joint) -> float:
	var ids := _joint_points(j)
	var jp := pos[ids[0]]
	var ap := (jp - pos[ids[1]]).angle()
	var ac := (pos[ids[2]] - jp).angle()
	return wrapf(ac - ap - j.center, -PI, PI)


func _solve_joints() -> void:
	var muscle := 0.0
	if frozen:
		muscle = 0.5
	elif not dead and not is_out():
		muscle = 0.06 * clampf(ko / 100.0, 0.0, 1.0)
	for j in joints:
		if not j.active:
			continue
		var ids := _joint_points(j)
		var jp_i: int = ids[0]
		var op_i: int = ids[1]
		var cp_i: int = ids[2]
		var jp := pos[jp_i]
		var rel := wrapf((pos[cp_i] - jp).angle() - (jp - pos[op_i]).angle() - j.center, -PI, PI)
		# A joint bent far past its limit counts as dislocated and stays loose.
		if absf(rel) > j.half + 0.8:
			continue
		var target := clampf(rel, -j.half, j.half)
		if muscle > 0.0:
			var goal := j.frozen_rel if frozen else j.rest
			target = lerpf(target, goal, muscle)
		var diff := target - rel
		if absf(diff) < 0.0001:
			continue
		var wc := 0.0 if cp_i == grabbed else inv_mass[cp_i]
		var wo := 0.0 if op_i == grabbed else inv_mass[op_i]
		var ws := wc + wo
		if ws <= 0.0:
			continue
		# Small steps keep a badly tangled joint from flipping between its two limits.
		diff = clampf(diff * 0.5, -0.12, 0.12)
		var nc := jp + (pos[cp_i] - jp).rotated(diff * wc / ws)
		var no := jp + (pos[op_i] - jp).rotated(-diff * wo / ws)
		var dc := nc - pos[cp_i]
		var d_o := no - pos[op_i]
		pos[cp_i] = nc
		pos[op_i] = no
		# Shift all three points so the rotation adds no linear momentum.
		var wj := 0.0 if jp_i == grabbed else inv_mass[jp_i]
		if wc > 0.0 and wo > 0.0 and wj > 0.0:
			var push := dc / wc + d_o / wo
			var shift := -push / (1.0 / wc + 1.0 / wo + 1.0 / wj)
			pos[cp_i] += shift
			pos[op_i] += shift
			pos[jp_i] += shift


## Moves a point that a constraint pushed into a solid cell back to free space.
## The point loses most of its speed so contacts drain energy instead of adding it.
func _push_out(i: int) -> void:
	var p := pos[i]
	if not world.is_solid_at(p):
		return
	var v := p - prev[i]
	var q := _free_spot(p, prev[i])
	pos[i] = q
	prev[i] = q - v * 0.25


func _free_spot(p: Vector2, back_to: Vector2) -> Vector2:
	# Smallest exit out of the current cell along one axis.
	var fx := floorf(p.x)
	var fy := floorf(p.y)
	var best := p
	var best_d := INF
	for q in [Vector2(p.x, fy - 0.001), Vector2(fx - 0.001, p.y), Vector2(fx + 1.001, p.y), Vector2(p.x, fy + 1.001)]:
		var d: float = q.distance_squared_to(p)
		if d < best_d and not world.is_solid_at(q):
			best_d = d
			best = q
	if best_d < INF:
		return best
	var back := back_to - p
	var n := int(ceilf(back.length()))
	for s in range(1, mini(n, 6) + 1):
		var q := p + back * (float(s) / n)
		if not world.is_solid_at(q):
			return q
	for r in range(1, 6):
		for dir in [Vector2.UP, Vector2(-1, -1), Vector2(1, -1), Vector2.LEFT, Vector2.RIGHT, Vector2.DOWN]:
			var q: Vector2 = p + dir * r
			if not world.is_solid_at(q):
				return q
	return p


# ---------------------------------------------------------------- damage

func _on_impact(i: int, speed: float) -> void:
	var k := owner_part[i]
	var force := speed - WOUND_SPEED * 0.75
	pn = minf(100.0, pn + force / 9.0)
	_damaged()
	if k == HEAD:
		ko -= force / 5.0
	if speed > WOUND_SPEED and _wound_cd <= 0.0:
		_wound_cd = 0.12
		var t := 0.15 if i == pa[k] else 0.85
		if k == HEAD:
			t = randf()
		var sev := 0.5 + (speed - WOUND_SPEED) / 180.0
		add_wound(k, t, randf_range(-1.0, 1.0), sev)
		_burst(pos[i], 4 + int(sev * 4), Vector2(0, -1), 70.0)
	var sever_at := SEVER_SPEED * (0.6 if frozen else 1.0)
	if k == HEAD:
		sever_at *= 1.3
	if k != TORSO and k != PELVIS and speed > sever_at and _sever_cd <= 0.0:
		if randf() < clampf((speed - sever_at) / 350.0 + 0.15, 0.0, 0.7):
			sever(k)


func add_wound(k: int, t: float, s: float, severity: float, stump := false) -> void:
	for w in wounds:
		if w.part == k and not w.stump and absf(w.t - t) < 0.2 and not stump:
			w.bleed = minf(1.0, w.bleed + severity * 0.12)
			w.size = mini(3, w.size + 1)
			return
	if wounds.size() >= MAX_WOUNDS:
		wounds.pop_front()
	var w := Wound.new()
	w.part = k
	w.t = clampf(t, 0.0, 1.0)
	w.s = clampf(s, -1.0, 1.0)
	w.bleed = severity * 0.25
	w.size = 1 if severity < 1.5 else 2
	w.stump = stump
	wounds.append(w)


func sever(k: int) -> void:
	if k == TORSO or severed[k]:
		return
	var jp := pa[k]
	var np := pos.size()
	pos.append(pos[jp])
	prev.append(prev[jp])
	inv_mass.append(inv_mass[jp])
	owner_part.append(k)
	impact_cd.append(0.3)
	pa[k] = np
	severed[k] = true
	for j in joints:
		if j.child == k:
			j.active = false
	var parent: int = PARENT[k]
	var parent_t := 0.0
	for d in JOINTS:
		if d[0] == k:
			parent_t = 0.0 if d[2] else 1.0
	add_wound(parent, parent_t, 0.0, 9.0, true)
	add_wound(k, 0.0, 0.0, 3.2, true)
	_sever_cd = 0.25
	if grabbed == jp:
		grabbed = -1
	pn = 100.0
	_burst(pos[jp], 26, Vector2(0, -1), 120.0)
	_damaged()
	if k == HEAD:
		_die()


## Blade stroke from a to b. Returns true when the stroke touches the doll.
func blade_hit(a: Vector2, b: Vector2, speed: float) -> bool:
	if speed < 60.0:
		return false
	var hit := false
	for k in PART_COUNT:
		var p0 := pos[pa[k]]
		var p1 := pos[pb[k]]
		var t := 0.5
		var dist := 0.0
		var contact := Vector2.ZERO
		if k == HEAD:
			contact = Geometry2D.get_closest_point_to_segment(p1, a, b)
			dist = contact.distance_to(p1) - HEAD_R
			t = randf()
		else:
			var cp := Geometry2D.get_closest_points_between_segments(a, b, p0, p1)
			contact = cp[1]
			dist = cp[0].distance_to(cp[1]) - WIDTH[k] * 0.5
			var seg := p1 - p0
			if seg.length_squared() > 0.0:
				t = clampf((contact - p0).dot(seg) / seg.length_squared(), 0.0, 1.0)
		if dist > 1.5:
			continue
		hit = true
		if blade_cd[k] > 0.0:
			continue
		blade_cd[k] = 0.15
		add_wound(k, t, randf_range(-1.0, 1.0), 0.6 + speed / 600.0)
		pn = minf(100.0, pn + 14.0)
		_burst(contact, 10, (b - a).normalized(), 90.0)
		if speed > 380.0 and k != TORSO and _sever_cd <= 0.0 and randf() < 0.8:
			sever(k)
	if hit:
		blade_timer = 2.0
		_damaged()
	return hit


func apply_heat(p: Vector2, radius: float) -> void:
	if _near(p, radius):
		burn_timer = maxf(burn_timer, 5.0)


func apply_cold(p: Vector2, radius: float, dt: float) -> void:
	if _near(p, radius):
		freeze = minf(1.6, freeze + dt * 1.1)
		burn_timer = 0.0


func _near(p: Vector2, radius: float) -> bool:
	for q in pos:
		if q.distance_to(p) <= radius:
			return true
	return false


func _damaged() -> void:
	since_damage = 0.0
	hurt_flash = 1.0


func _die() -> void:
	dead = true
	ko = 0.0


func _burst(p: Vector2, count: int, dir: Vector2, speed: float) -> void:
	if bl <= 1.0:
		return
	for _n in count:
		var v := (dir * speed * randf_range(0.3, 1.0)).rotated(randf_range(-1.1, 1.1))
		v += Vector2(randf_range(-30, 30), randf_range(-50, 10))
		world.spawn_particle(p, v, World.BLOOD)


# ---------------------------------------------------------------- effects

func _update_effects(dt: float) -> void:
	_sever_cd = maxf(0.0, _sever_cd - dt)
	_wound_cd = maxf(0.0, _wound_cd - dt)
	for k in PART_COUNT:
		blade_cd[k] = maxf(0.0, blade_cd[k] - dt)
	blade_timer = maxf(0.0, blade_timer - dt)
	hurt_flash = maxf(0.0, hurt_flash - dt * 4.0)
	beat_flash = maxf(0.0, beat_flash - dt * 5.0)

	var cold := 0
	var wet := false
	for i in pos.size():
		var m := world.get_mat_at(pos[i])
		if m == World.FIRE and burn_timer <= 0.0 and _burn_immune <= 0.0:
			burn_timer = 5.0
		elif m == World.WATER or m == World.BLOOD:
			wet = true
		if world.get_mat_at(pos[i] + Vector2(0, 1.5)) == World.ICE or world.get_mat_at(pos[i] + Vector2(1.5, 0)) == World.ICE or world.get_mat_at(pos[i] - Vector2(1.5, 0)) == World.ICE:
			cold += 1
	var head := pos[pb[HEAD]]
	head_under = not severed[HEAD] and world.is_liquid_at(head) and world.is_liquid_at(head - Vector2(0, 2))

	if wet and burn_timer > 0.0:
		burn_timer = 0.0
		world.paint(pos[pa[TORSO]], 3.0, World.STEAM, 0.4, 60)

	_burn_immune = maxf(0.0, _burn_immune - dt)
	if burn_timer > 0.0:
		burn_timer -= dt
		if burn_timer <= 0.0:
			_burn_immune = 1.5
		freeze = maxf(0.0, freeze - dt * 0.9)
		pn = minf(100.0, pn + 9.0 * dt)
		since_damage = 0.0
		for _n in 2:
			var k := randi() % PART_COUNT
			var p := pos[pa[k]].lerp(pos[pb[k]], randf())
			char_lvl[k] = minf(1.0, char_lvl[k] + dt * 0.25)
			if world.get_mat_at(p - Vector2(0, 2)) == World.EMPTY:
				world.set_cell(int(p.x) + randi() % 3 - 1, int(p.y) - 2, World.FIRE, 0, 30 + randi() % 40)

	if cold > 0:
		freeze = minf(1.6, freeze + dt * 0.18 * mini(cold, 5))
	elif burn_timer <= 0.0:
		freeze = maxf(0.0, freeze - dt * 0.06)
	if not frozen and freeze >= 1.0:
		frozen = true
		for j in joints:
			j.frozen_rel = _joint_rel(j)
	elif frozen and freeze < 0.5:
		frozen = false

	# Bleeding: drips from every open wound, spurts from stumps on each heartbeat.
	var flow := 0.0 if bl <= 0.0 else clampf(bl / 100.0, 0.2, 1.0)
	if dead:
		flow *= 0.25
	for w in wounds:
		if w.bleed <= 0.0 or flow <= 0.0:
			continue
		var wp := wound_pos(w)
		if randf() < w.bleed * dt * 7.0 * flow:
			var dn := _wound_normal(w)
			world.spawn_particle(wp, dn * randf_range(5, 25) + Vector2(randf_range(-6, 6), 0), World.BLOOD)
		if w.stump and _beat:
			var out := _stump_dir(w)
			for _n in 3 + int(w.bleed * 1.5):
				var v := out.rotated(randf_range(-0.35, 0.35)) * randf_range(50, 110) * flow
				world.spawn_particle(wp, v, World.BLOOD)


func wound_pos(w: Wound) -> Vector2:
	var a := pos[pa[w.part]]
	var b := pos[pb[w.part]]
	if w.part == HEAD:
		if w.stump:
			return a
		return b + Vector2.from_angle(w.t * TAU) * (HEAD_R - 1.5)
	var d := (b - a).normalized()
	return a.lerp(b, w.t) + d.orthogonal() * w.s * maxf(0.0, WIDTH[w.part] * 0.5 - 0.5)


func _wound_normal(w: Wound) -> Vector2:
	var a := pos[pa[w.part]]
	var b := pos[pb[w.part]]
	if w.part == HEAD:
		return Vector2.from_angle(w.t * TAU)
	var n := (b - a).normalized().orthogonal()
	return n * (1.0 if w.s >= 0.0 else -1.0)


func _stump_dir(w: Wound) -> Vector2:
	var a := pos[pa[w.part]]
	var b := pos[pb[w.part]]
	var d := (a - b).normalized() if w.t < 0.5 else (b - a).normalized()
	if d == Vector2.ZERO:
		d = Vector2.UP
	return d


# ---------------------------------------------------------------- vitals

func _update_vitals(dt: float) -> void:
	_beat = false
	since_damage += dt
	var bleed_total := 0.0
	for w in wounds:
		bleed_total += w.bleed
	bl = maxf(0.0, bl - bleed_total * dt * (0.2 if dead else 0.8))

	if head_under and not dead:
		o2 = maxf(0.0, o2 - 11.0 * dt)
	else:
		o2 = minf(100.0, o2 + 20.0 * dt)
	_no_air = _no_air + dt if o2 <= 0.0 else 0.0

	healing = not dead and since_damage > 4.0 and burn_timer <= 0.0 and not head_under \
		and (bl < 99.9 or pn > 0.5 or ko < 99.0 or o2 < 99.0 or bleed_total > 0.0)
	if healing:
		bl = minf(100.0, bl + 1.2 * dt)
		pn = maxf(0.0, pn - 6.0 * dt)
		for w in wounds:
			w.bleed = maxf(0.0, w.bleed - (0.05 if w.stump else 0.14) * dt)
	pn = maxf(0.0, pn - 3.0 * dt)

	var cap := 100.0
	if bl < 55.0:
		cap = (bl - 30.0) * 4.0
	if o2 < 40.0:
		cap = minf(cap, o2 * 2.5)
	if frozen:
		cap = minf(cap, 30.0)
	if pn > 85.0:
		cap = minf(cap, 60.0)
	cap = maxf(0.0, cap)
	if dead:
		ko = 0.0
	elif ko > cap:
		ko = move_toward(ko, cap, 25.0 * dt)
	else:
		ko = move_toward(ko, cap, (6.0 if healing else 2.0) * dt)
	ko = clampf(ko, 0.0, 100.0)

	if not dead and (bl <= 8.0 or _no_air > 6.0):
		_die()

	var target := 72.0 + pn * 0.5 + maxf(0.0, 100.0 - bl) * 0.9
	if o2 < 50.0:
		target -= (50.0 - o2) * 1.4
	if frozen:
		target = 38.0
	if dead:
		target = 0.0
	hr = move_toward(hr, maxf(0.0, target), 30.0 * dt)
	if hr > 1.0:
		beat_phase += dt * hr / 60.0
		if beat_phase >= 1.0:
			beat_phase -= 1.0
			_beat = true
			beat_flash = 1.0


# ---------------------------------------------------------------- state for the UI

func is_out() -> bool:
	return dead or ko <= 10.0 or bl < OUT_BL


func is_attached(k: int) -> bool:
	while k >= 0:
		if severed[k]:
			return false
		k = PARENT[k]
	return true


func flags() -> Dictionary:
	var bleeding := false
	for w in wounds:
		if w.bleed > 0.0:
			bleeding = true
			break
	return {
		"OUT": is_out(),
		"BLEED": bleeding and bl > 0.0,
		"FIRE": burn_timer > 0.0,
		"CHOKE": head_under and not dead,
		"AGONY": pn >= AGONY_PN and not dead,
		"HEAL": healing,
		"BLADE": blade_timer > 0.0,
		"TORN": severed.has(true),
		"FROZEN": frozen,
	}


func nearest_point(p: Vector2, radius: float) -> int:
	var best := -1
	var best_d := radius
	for i in pos.size():
		var d := pos[i].distance_to(p)
		if d < best_d:
			best_d = d
			best = i
	return best


func grab(i: int, target: Vector2) -> void:
	grabbed = i
	grab_target = target


func release() -> void:
	grabbed = -1


func center() -> Vector2:
	return pos[P_WAIST]


# ---------------------------------------------------------------- drawing

func _part_color(k: int) -> Color:
	var c := COL_SKIN_FAR if FAR_SIDE[k] else COL_SKIN
	if dead:
		c = c.darkened(0.08)
	c = c.lerp(COL_CHAR, clampf(char_lvl[k], 0.0, 0.9))
	if frozen:
		c = c.lerp(COL_ICE, 0.6)
	if hurt_flash > 0.0:
		c = c.lerp(Color("ff7070"), hurt_flash * 0.35)
	return c


func _draw_part(k: int, col: Color, grow: float) -> void:
	var a := pos[pa[k]]
	var b := pos[pb[k]]
	if k == HEAD:
		draw_line(a, b, col, 2.0 + grow * 2.0)
		draw_circle(b, HEAD_R + grow, col)
		return
	var w: float = WIDTH[k] + grow * 2.0
	draw_line(a, b, col, w)
	draw_circle(a, w * 0.5, col)
	draw_circle(b, w * 0.5, col)


func _draw() -> void:
	for k in DRAW_ORDER:
		_draw_part(k, COL_LINE, 1.0)
		_draw_part(k, _part_color(k), 0.0)
	for w in wounds:
		var wp := wound_pos(w).floor()
		var col := COL_WOUND if w.bleed > 0.0 else COL_SCAR
		if w.stump:
			draw_rect(Rect2(wp - Vector2(1, 1), Vector2(3, 3)), COL_STUMP if w.bleed > 0.0 else COL_SCAR)
		else:
			draw_rect(Rect2(wp, Vector2(w.size, w.size)), col)
	_draw_face()


func _draw_face() -> void:
	var neck := pos[pa[HEAD]]
	var hc := pos[pb[HEAD]]
	var up := (hc - neck).normalized()
	if up == Vector2.ZERO:
		up = Vector2.UP
	var fwd := up.rotated(PI * 0.5)
	var eye := (hc + fwd * 2.0 + up * 0.5).floor()
	if dead or is_out():
		var c := COL_LINE
		if dead:
			draw_rect(Rect2(eye + Vector2(-1, -1), Vector2.ONE), c)
			draw_rect(Rect2(eye + Vector2(1, -1), Vector2.ONE), c)
			draw_rect(Rect2(eye, Vector2.ONE), c)
			draw_rect(Rect2(eye + Vector2(-1, 1), Vector2.ONE), c)
			draw_rect(Rect2(eye + Vector2(1, 1), Vector2.ONE), c)
		else:
			draw_rect(Rect2(eye + Vector2(-1, 0), Vector2(2, 1)), c)
	else:
		draw_rect(Rect2(eye, Vector2.ONE), COL_LINE)
