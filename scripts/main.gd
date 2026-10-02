extends Node2D
## Builds the scene, routes input to the tools and runs the fixed step.

const MAX_DOLLS := 6
const GRAB_RADIUS := 9.0
const LAMP := Vector2(192, 21)

var world: World
var dolls_root: Node2D
var ui: GameUI
var light: Sprite2D

var tool := GameUI.T_GRAB
var mouse := Vector2.ZERO
var last_mouse := Vector2.ZERO
var pressing := false
var blade_trail: Array = []

var _selected: Doll
var _grab_doll: Doll
var _doll_counter := 0


func _ready() -> void:
	randomize()
	add_child(Background.new())
	# Dolls sit behind the grid so water, fire and smoke cover them.
	dolls_root = Node2D.new()
	add_child(dolls_root)
	world = World.new()
	add_child(world)
	light = Sprite2D.new()
	light.centered = false
	light.texture = _make_light()
	var lm := CanvasItemMaterial.new()
	lm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	light.material = lm
	add_child(light)
	ui = GameUI.new()
	ui.main = self
	add_child(ui)
	reset_scene()


func reset_scene() -> void:
	world.reset()
	for d in dolls_root.get_children():
		d.queue_free()
	_selected = null
	_grab_doll = null
	_doll_counter = 0
	spawn_doll(Vector2(World.W * 0.5 - 30, World.FLOOR_Y))


func spawn_doll(base: Vector2) -> Doll:
	var alive := dolls_root.get_children().filter(func(n): return not n.is_queued_for_deletion())
	if alive.size() >= MAX_DOLLS:
		var oldest: Doll = alive[0]
		if oldest == _grab_doll:
			_grab_doll = null
		oldest.queue_free()
	_doll_counter += 1
	var d := Doll.new()
	dolls_root.add_child(d)
	d.setup(world, base, _doll_counter)
	_selected = d
	return d


func dolls() -> Array:
	return dolls_root.get_children().filter(func(n): return not n.is_queued_for_deletion())


func selected_doll() -> Doll:
	if _selected != null and is_instance_valid(_selected) and not _selected.is_queued_for_deletion():
		return _selected
	var all := dolls()
	_selected = all[-1] if not all.is_empty() else null
	return _selected


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse = get_global_mouse_position()
		if event.pressed:
			_press()
		else:
			_release()
	elif event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k >= KEY_1 and k <= KEY_7:
			_use_button(k - KEY_1)
		elif k == KEY_R:
			_use_button(GameUI.T_RESET)
		elif k == KEY_N:
			_use_button(GameUI.T_DOLL)


func _press() -> void:
	var btn := ui.toolbar_hit(mouse)
	if btn >= 0:
		_use_button(btn)
		return
	if ui.blocks_input(mouse):
		return
	pressing = true
	last_mouse = mouse
	if tool == GameUI.T_GRAB:
		var best_d := GRAB_RADIUS
		for d in dolls():
			var i: int = d.nearest_point(mouse, best_d)
			if i >= 0:
				best_d = d.pos[i].distance_to(mouse)
				_grab_doll = d
				d.release()
				d.grab(i, mouse)
		if _grab_doll != null:
			for d in dolls():
				if d != _grab_doll:
					d.release()
			_selected = _grab_doll


func _release() -> void:
	pressing = false
	if _grab_doll != null and is_instance_valid(_grab_doll):
		_grab_doll.release()
	_grab_doll = null


func _use_button(idx: int) -> void:
	match idx:
		GameUI.T_DOLL:
			var d := spawn_doll(Vector2(LAMP.x + randf_range(-30, 30), 80))
			for i in d.pos.size():
				d.prev[i] = d.pos[i] + Vector2(randf_range(-1, 1), -1)
		GameUI.T_RESET:
			reset_scene()
		_:
			_release()
			tool = idx


# ---------------------------------------------------------------- frame

func _physics_process(dt: float) -> void:
	mouse = get_global_mouse_position()
	ui.hover = ui.toolbar_hit(mouse)
	if pressing:
		_apply_tool(dt)
	world.step(dt)
	for d in dolls():
		if d == _grab_doll:
			d.grab_target = mouse
		d.step(dt)
	for seg in blade_trail:
		seg[2] += dt
	blade_trail = blade_trail.filter(func(s): return s[2] < 0.25)
	last_mouse = mouse
	ui.queue_redraw()


func _apply_tool(dt: float) -> void:
	match tool:
		GameUI.T_WATER:
			for _n in 5:
				var v := Vector2(randf_range(-12, 12), randf_range(10, 40))
				world.spawn_particle(mouse + Vector2(randf_range(-1.5, 1.5), 0), v, World.WATER, 0)
		GameUI.T_FIRE:
			world.paint(mouse, 4.0, World.FIRE, 0.3)
			for d in dolls():
				d.apply_heat(mouse, 6.0)
		GameUI.T_ICE:
			world.paint(mouse, 3.5, World.ICE, 0.6, 200)
			for d in dolls():
				d.apply_cold(mouse, 7.0, dt)
		GameUI.T_BLADE:
			var speed := mouse.distance_to(last_mouse) / dt
			if mouse != last_mouse:
				blade_trail.append([last_mouse, mouse, 0.0])
				for d in dolls():
					if d.blade_hit(last_mouse, mouse, speed):
						_selected = d


# ---------------------------------------------------------------- light

## Soft cone of warm light, baked once into a texture and drawn additive.
func _make_light() -> ImageTexture:
	var bytes := PackedByteArray()
	bytes.resize(World.W * World.H * 4)
	var bayer := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	var half_angle := deg_to_rad(27.0)
	var soft := deg_to_rad(9.0)
	var warm := Color("fff0cc")
	for y in World.H:
		for x in World.W:
			var dx := x + 0.5 - LAMP.x
			var dy := y + 0.5 - LAMP.y
			var glow := 0.0
			var r := sqrt(dx * dx + dy * dy)
			if r < 26.0:
				glow = pow(1.0 - r / 26.0, 2.0) * 0.55
			var cone := 0.0
			if dy > 0.0:
				var ang := atan2(absf(dx), dy)
				var edge := clampf((half_angle + soft - ang) / (soft * 2.0), 0.0, 1.0)
				edge = edge * edge * (3.0 - 2.0 * edge)
				var fall := pow(clampf(1.0 - dy / 240.0, 0.0, 1.0), 1.2)
				cone = edge * fall * 0.2
				if y >= World.FLOOR_Y and y < World.FLOOR_Y + 5:
					cone *= 1.6
			var v := clampf(glow + cone, 0.0, 1.0)
			# Ordered dither keeps the gradient soft but still pixel crisp.
			var th: float = (bayer[(y % 4) * 4 + (x % 4)] + 0.5) / 16.0
			v = floorf(v * 48.0 + th) / 48.0
			var o := (y * World.W + x) * 4
			bytes[o] = int(warm.r * 255)
			bytes[o + 1] = int(warm.g * 255)
			bytes[o + 2] = int(warm.b * 255)
			bytes[o + 3] = int(v * 255)
	var img := Image.create_from_data(World.W, World.H, false, Image.FORMAT_RGBA8, bytes)
	return ImageTexture.create_from_image(img)
