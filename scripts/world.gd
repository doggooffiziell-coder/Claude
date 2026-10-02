class_name World
extends Node2D
## Falling-sand pixel grid. Every cell holds one material.
## The grid renders into an Image that is uploaded to an ImageTexture.
## Only chunks with recent changes are simulated.

enum { EMPTY, WALL, WATER, BLOOD, FIRE, ICE, STEAM, SMOKE }

const W := 384
const H := 216
const FLOOR_Y := 186
const CHUNK := 16
const CW := W / CHUNK
const CH := (H + CHUNK - 1) / CHUNK
const GRAVITY := 420.0
const MAX_PARTICLES := 1800

const COL_WATER := Color("2f63c4")
const COL_VIOLET := Color("6e2c96")
const COL_BLOOD := Color("7a0c14")

var mat := PackedByteArray()
var mixv := PackedByteArray()   # blood share inside water, 0..255
var life := PackedByteArray()   # lifetime for fire and gas, coldness for ice
var shade := PackedByteArray()  # static per cell noise for texture
var stamp := PackedByteArray()  # marks cells already moved this tick
var rest := PackedByteArray()   # counts ticks a liquid cell stayed put
var pixels := PackedByteArray()
var paint_list := PackedInt32Array()
var paint_mark := PackedByteArray()
var water_lut := PackedByteArray()   # rgb for every blood share, plain and surface
var chunk_now := PackedByteArray()
var chunk_next := PackedByteArray()

var image: Image
var texture: ImageTexture
var tick := 0
var cur_stamp := 1
var dirty := true

# Free flying droplets. They turn back into grid cells when they land.
var p_pos := PackedVector2Array()
var p_vel := PackedVector2Array()
var p_mat := PackedByteArray()
var p_mix := PackedByteArray()


func _ready() -> void:
	var n := W * H
	mat.resize(n)
	mixv.resize(n)
	life.resize(n)
	shade.resize(n)
	stamp.resize(n)
	rest.resize(n)
	pixels.resize(n * 4)
	paint_mark.resize(n)
	_build_water_lut()
	chunk_now.resize(CW * CH)
	chunk_next.resize(CW * CH)
	for i in n:
		shade[i] = randi() % 16
	image = Image.create_from_data(W, H, false, Image.FORMAT_RGBA8, pixels)
	texture = ImageTexture.create_from_image(image)
	reset()


func reset() -> void:
	mat.fill(EMPTY)
	mixv.fill(0)
	life.fill(0)
	stamp.fill(0)
	rest.fill(0)
	chunk_now.fill(0)
	chunk_next.fill(0)
	for y in range(FLOOR_Y, H):
		for x in W:
			mat[y * W + x] = WALL
	p_pos.clear()
	p_vel.clear()
	p_mat.clear()
	p_mix.clear()
	paint_list.clear()
	paint_mark.fill(0)
	for i in W * H:
		_paint(i)
	dirty = true
	_upload()


# ---------------------------------------------------------------- queries

func get_mat(x: int, y: int) -> int:
	if x < 0 or x >= W or y < 0 or y >= H:
		return WALL
	return mat[y * W + x]


func get_mat_at(p: Vector2) -> int:
	return get_mat(int(floorf(p.x)), int(floorf(p.y)))


func is_solid(x: int, y: int) -> bool:
	var m := get_mat(x, y)
	return m == WALL or m == ICE


func is_solid_at(p: Vector2) -> bool:
	return is_solid(int(floorf(p.x)), int(floorf(p.y)))


func is_liquid_at(p: Vector2) -> bool:
	var m := get_mat_at(p)
	return m == WATER or m == BLOOD


func count_near(p: Vector2, radius: int, m: int) -> int:
	var cx := int(floorf(p.x))
	var cy := int(floorf(p.y))
	var c := 0
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if get_mat(cx + dx, cy + dy) == m:
				c += 1
	return c


# ---------------------------------------------------------------- editing

func set_cell(x: int, y: int, m: int, mx := 0, lf := 0) -> void:
	if x < 0 or x >= W or y < 0 or y >= H:
		return
	var i := y * W + x
	mat[i] = m
	mixv[i] = mx
	life[i] = lf
	_touch(i)


## Fills a disc with a material. Only empty or gas cells are replaced.
func paint(center: Vector2, radius: float, m: int, chance: float, lf := 0) -> void:
	var r := int(ceilf(radius))
	var cx := int(floorf(center.x))
	var cy := int(floorf(center.y))
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy > radius * radius or randf() > chance:
				continue
			var x := cx + dx
			var y := cy + dy
			var cur := get_mat(x, y)
			if cur == EMPTY or cur == STEAM or cur == SMOKE:
				var l := lf
				if m == FIRE:
					l = 40 + randi() % 50
				set_cell(x, y, m, 0, l)


func spawn_particle(pos: Vector2, vel: Vector2, m: int, mx := 255) -> void:
	if p_pos.size() >= MAX_PARTICLES:
		return
	p_pos.append(pos)
	p_vel.append(vel)
	p_mat.append(m)
	p_mix.append(mx)


## Throws a liquid cell out of the way of a fast moving body point.
func splash(p: Vector2, vel: Vector2) -> void:
	var x := int(floorf(p.x))
	var y := int(floorf(p.y))
	var m := get_mat(x, y)
	if m != WATER and m != BLOOD:
		return
	var i := y * W + x
	var mx := mixv[i]
	set_cell(x, y, EMPTY)
	var out := Vector2(vel.x * 0.5 + randf_range(-25, 25), -absf(vel.y) * 0.45 - randf_range(20, 60))
	spawn_particle(Vector2(x + 0.5, y - 0.5), out, m, mx if m == WATER else 255)


# ---------------------------------------------------------------- simulation

func step(dt: float) -> void:
	tick += 1
	cur_stamp = (tick % 250) + 1
	var swap := chunk_now
	chunk_now = chunk_next
	chunk_next = swap
	chunk_next.fill(0)

	var left_first := (tick & 1) == 0
	for cy in range(CH - 1, -1, -1):
		var any := false
		for cx in CW:
			if chunk_now[cy * CW + cx] != 0:
				any = true
				break
		if not any:
			continue
		var y0 := cy * CHUNK
		var y1 := mini(y0 + CHUNK, H) - 1
		for y in range(y1, y0 - 1, -1):
			for ci in CW:
				var cx := ci if left_first else CW - 1 - ci
				if chunk_now[cy * CW + cx] == 0:
					continue
				var x0 := cx * CHUNK
				for k in CHUNK:
					var x := x0 + k if left_first else x0 + CHUNK - 1 - k
					var i := y * W + x
					var m := mat[i]
					if m == EMPTY or m == WALL or m == ICE:
						continue
					if stamp[i] == cur_stamp:
						continue
					if rest[i] > 3 and ((tick + i) & 15) != 0:
						continue
					match m:
						WATER, BLOOD:
							_liquid(x, y, i, m)
						FIRE:
							_fire(x, y, i)
						STEAM, SMOKE:
							_gas(x, y, i)

	_step_particles(dt)
	_upload()
	queue_redraw()


func _is_free(m: int) -> bool:
	return m == EMPTY or m == STEAM or m == SMOKE


func _liquid(x: int, y: int, i: int, m: int) -> void:
	var has_below := y + 1 < H
	if has_below:
		var b := i + W
		var mb := mat[b]
		if mb == EMPTY or mb >= STEAM:
			_swap(i, b)
			life[b] = 0
			return
		var d := 1 if (randi() & 1) == 0 else -1
		for _k in 2:
			var nx := x + d
			if nx >= 0 and nx < W:
				var md := mat[b + d]
				var ms := mat[i + d]
				if (md == EMPTY or md >= STEAM) and (ms == EMPTY or ms >= STEAM):
					_swap(i, b + d)
					life[b + d] = 0
					return
			d = -d
	# Look sideways for a drop and flow toward it. Water looks far, blood is thick.
	var look := 32 if m == WATER else 3
	var dir := 1 if (randi() & 1) == 0 else -1
	var row := y * W
	for _k in 2:
		var nx := x
		var s := 0
		var found := false
		while s < look:
			var tx := nx + dir
			if tx < 0 or tx >= W:
				break
			var mt := mat[row + tx]
			if not (mt == EMPTY or mt >= STEAM):
				break
			nx = tx
			s += 1
			if has_below:
				var mu := mat[row + W + tx]
				if mu == EMPTY or mu >= STEAM:
					found = true
					break
		if found:
			var stride := mini(s, 4 if m == WATER else 1)
			_swap(i, row + x + dir * stride)
			return
		dir = -dir
	# No drop in reach: spread sideways at random so pools level out.
	# Every random hop tires the cell, so a flat pool comes to rest.
	var tired := int(life[i])
	if tired < 48 and (m == WATER or (randi() & 3) == 0):
		for _k in 2:
			var tx := x + dir
			if tx >= 0 and tx < W:
				var mt := mat[row + tx]
				if mt == EMPTY or mt >= STEAM:
					var tx2 := tx + dir
					if m == WATER and tx2 >= 0 and tx2 < W:
						var mt2 := mat[row + tx2]
						if mt2 == EMPTY or mt2 >= STEAM:
							tx = tx2
					_swap(i, row + tx)
					life[row + tx] = tired + 1
					return
			dir = -dir
	if rest[i] < 255:
		rest[i] += 1
	if (randi() & 3) == 0:
		_liquid_react(x, y, i, m)


func _liquid_react(x: int, y: int, i: int, m: int) -> void:
	var j := _rand_neighbor(x, y)
	if j < 0:
		return
	var mj := mat[j]
	if mj == WATER or mj == BLOOD:
		var fa := 255 if m == BLOOD else int(mixv[i])
		var fb := 255 if mj == BLOOD else int(mixv[j])
		if absi(fa - fb) > 6:
			var avg := (fa + fb) >> 1
			_set_liquid(i, avg)
			_set_liquid(j, avg)
	elif mj == ICE and m == WATER and life[j] > 40 and randi() % 5 == 0:
		mat[i] = ICE
		life[i] = life[j] - 40
		_touch(i)


func _set_liquid(i: int, share: int) -> void:
	if share >= 250:
		mat[i] = BLOOD
		mixv[i] = 255
	else:
		mat[i] = WATER
		mixv[i] = share
	_touch(i)


func _fire(x: int, y: int, i: int) -> void:
	var l := int(life[i]) - 1 - randi() % 3
	if l <= 0:
		if randi() % 3 == 0:
			mat[i] = SMOKE
			life[i] = 50 + randi() % 40
		else:
			mat[i] = EMPTY
			life[i] = 0
		_touch(i)
		return
	life[i] = l
	for n in 4:
		var j := _neighbor(x, y, n)
		if j < 0:
			continue
		var mj := mat[j]
		if mj == WATER or mj == BLOOD:
			mat[i] = STEAM
			life[i] = 60
			if randi() % 2 == 0:
				mat[j] = STEAM
				life[j] = 70
				_touch(j)
			_touch(i)
			return
		if mj == ICE and randi() % 4 == 0:
			mat[j] = WATER
			mixv[j] = 0
			life[j] = 0
			_touch(j)
	var nx := x + randi() % 3 - 1
	if y > 0 and nx >= 0 and nx < W and _is_free(mat[(y - 1) * W + nx]) and randi() % 3 != 0:
		_swap(i, (y - 1) * W + nx)
	else:
		_touch(i)


func _gas(x: int, y: int, i: int) -> void:
	var l := int(life[i]) - 1
	if y == 0:
		l -= 3
	if l <= 0:
		mat[i] = EMPTY
		life[i] = 0
		_touch(i)
		return
	life[i] = l
	var nx := x + randi() % 3 - 1
	if y > 0 and nx >= 0 and nx < W and mat[(y - 1) * W + nx] == EMPTY:
		_swap(i, (y - 1) * W + nx)
		return
	var sx := x + (1 if (randi() & 1) == 0 else -1)
	if sx >= 0 and sx < W and mat[y * W + sx] == EMPTY:
		_swap(i, y * W + sx)
		return
	_touch(i)


func _neighbor(x: int, y: int, n: int) -> int:
	match n:
		0:
			return y * W + x - 1 if x > 0 else -1
		1:
			return y * W + x + 1 if x < W - 1 else -1
		2:
			return (y - 1) * W + x if y > 0 else -1
		_:
			return (y + 1) * W + x if y < H - 1 else -1


func _rand_neighbor(x: int, y: int) -> int:
	return _neighbor(x, y, randi() % 4)


func _swap(i: int, j: int) -> void:
	var t := mat[i]
	mat[i] = mat[j]
	mat[j] = t
	t = mixv[i]
	mixv[i] = mixv[j]
	mixv[j] = t
	t = life[i]
	life[i] = life[j]
	life[j] = t
	stamp[i] = cur_stamp
	stamp[j] = cur_stamp
	_touch(i)
	_touch(j)


## Wakes the chunk of a cell (and the bordering chunk) and repaints it.
func _touch(i: int) -> void:
	var x := i % W
	var y := i / W
	var cx := x >> 4
	var cy := y >> 4
	chunk_next[cy * CW + cx] = 1
	var lx := x & 15
	var ly := y & 15
	if lx == 0 and cx > 0:
		chunk_next[cy * CW + cx - 1] = 1
	elif lx == 15 and cx < CW - 1:
		chunk_next[cy * CW + cx + 1] = 1
	if ly == 0 and cy > 0:
		chunk_next[(cy - 1) * CW + cx] = 1
	elif ly == 15 and cy < CH - 1:
		chunk_next[(cy + 1) * CW + cx] = 1
	# Wake resting neighbours that could move into this cell.
	rest[i] = 0
	if x > 0:
		rest[i - 1] = 0
	if x < W - 1:
		rest[i + 1] = 0
	if y > 0:
		var u := i - W
		rest[u] = 0
		if x > 0:
			rest[u - 1] = 0
		if x < W - 1:
			rest[u + 1] = 0
	if paint_mark[i] == 0:
		paint_mark[i] = 1
		paint_list.append(i)
	if y + 1 < H and paint_mark[i + W] == 0:
		paint_mark[i + W] = 1
		paint_list.append(i + W)
	dirty = true


func _step_particles(dt: float) -> void:
	var k := p_pos.size() - 1
	while k >= 0:
		var v := p_vel[k]
		v.y += GRAVITY * dt
		v *= 0.995
		var p0 := p_pos[k]
		var p1 := p0 + v * dt
		var n := int(maxf(absf(p1.x - p0.x), absf(p1.y - p0.y))) + 1
		var done := false
		var last := p0
		for s in range(1, n + 1):
			var q := p0.lerp(p1, float(s) / n)
			var qx := int(floorf(q.x))
			var qy := int(floorf(q.y))
			if qx < 0 or qx >= W or qy >= H:
				done = true
				break
			if qy < 0:
				last = q
				continue
			var mq := mat[qy * W + qx]
			if not _is_free(mq):
				_settle(last, p_mat[k], p_mix[k])
				done = true
				break
			last = q
		if done:
			var e := p_pos.size() - 1
			p_pos[k] = p_pos[e]
			p_vel[k] = p_vel[e]
			p_mat[k] = p_mat[e]
			p_mix[k] = p_mix[e]
			p_pos.resize(e)
			p_vel.resize(e)
			p_mat.resize(e)
			p_mix.resize(e)
		else:
			p_pos[k] = p1
			p_vel[k] = v
		k -= 1


func _settle(p: Vector2, m: int, mx: int) -> void:
	var x := int(floorf(p.x))
	var y := int(floorf(p.y))
	for _k in 4:
		if y < 0:
			return
		if _is_free(get_mat(x, y)):
			if m == BLOOD:
				set_cell(x, y, BLOOD, 255)
			else:
				set_cell(x, y, m, mx)
			return
		y -= 1


# ---------------------------------------------------------------- rendering

func _paint(i: int) -> void:
	var o := i * 4
	var m := mat[i]
	var r := 0
	var g := 0
	var b := 0
	var a := 255
	match m:
		EMPTY:
			a = 0
		WALL:
			var x := i % W
			var y := i / W
			var s := int(shade[i])
			var v := 150 + (s >> 2)
			if y == FLOOR_Y:
				v = 204
			elif y == FLOOR_Y + 1:
				v = 178
			elif x % 32 == 0 or (y - FLOOR_Y) % 12 == 0:
				v = 128
			elif x % 32 == 1 or (y - FLOOR_Y) % 12 == 1:
				v = 168
			elif s == 0:
				v = 138
			r = v
			g = v
			b = v + 4
		WATER:
			var li := int(mixv[i]) * 6
			if i >= W and _is_free(mat[i - W]):
				li += 3
			r = water_lut[li]
			g = water_lut[li + 1]
			b = water_lut[li + 2]
			if shade[i] < 2:
				r = mini(255, r + 10)
				g = mini(255, g + 10)
				b = mini(255, b + 10)
			a = 190
		BLOOD:
			var s2 := int(shade[i]) % 4
			r = 112 + s2 * 4
			g = 8 + s2
			b = 16
			if i >= W and _is_free(mat[i - W]):
				r = 150
				g = 22
				b = 30
		FIRE:
			var l := int(life[i]) + randi() % 12
			if l > 60:
				r = 255
				g = 226
				b = 110
			elif l > 32:
				r = 246
				g = 132
				b = 34
			else:
				r = 190
				g = 44
				b = 22
		ICE:
			var s3 := int(shade[i])
			r = 168 + s3
			g = 214 + (s3 >> 1)
			b = 240
			if i >= W and mat[i - W] != ICE:
				r = 222
				g = 244
				b = 255
			a = 235
		STEAM:
			r = 205
			g = 210
			b = 220
			a = mini(150, int(life[i]) * 2)
		SMOKE:
			r = 58
			g = 58
			b = 62
			a = mini(170, int(life[i]) * 2)
	pixels[o] = r
	pixels[o + 1] = g
	pixels[o + 2] = b
	pixels[o + 3] = a


func _water_color(share: int) -> Color:
	var t := sqrt(share / 255.0)
	if t < 0.5:
		return COL_WATER.lerp(COL_VIOLET, t * 2.0)
	return COL_VIOLET.lerp(COL_BLOOD, (t - 0.5) * 2.0)


func _build_water_lut() -> void:
	water_lut.resize(256 * 6)
	for share in 256:
		var c := _water_color(share)
		var top := c.lightened(0.45)
		var o := share * 6
		water_lut[o] = int(c.r * 255)
		water_lut[o + 1] = int(c.g * 255)
		water_lut[o + 2] = int(c.b * 255)
		water_lut[o + 3] = int(top.r * 255)
		water_lut[o + 4] = int(top.g * 255)
		water_lut[o + 5] = int(top.b * 255)


func _upload() -> void:
	if not dirty:
		return
	for i in paint_list:
		_paint(i)
		paint_mark[i] = 0
	paint_list.clear()
	image.set_data(W, H, false, Image.FORMAT_RGBA8, pixels)
	texture.update(image)
	dirty = false


func _particle_color(k: int) -> Color:
	match p_mat[k]:
		BLOOD:
			return Color("a0101c")
		WATER:
			return _water_color(p_mix[k]).lightened(0.25)
		FIRE:
			return Color("ffc048")
	return Color.WHITE


func _draw() -> void:
	draw_texture(texture, Vector2.ZERO)
	for k in p_pos.size():
		draw_rect(Rect2(p_pos[k].floor(), Vector2.ONE), _particle_color(k))
