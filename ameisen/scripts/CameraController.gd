extends Camera2D
## Zoomen und Verschieben: zwei Finger auf Handy und Tablet, Mausrad und Rechtsklick am PC.
## Ein kurzes Tippen oder ein Linksklick meldet die Weltposition über das Signal tapped.

signal tapped(world_pos: Vector2)

const MAX_ZOOM := 6.0
const TAP_MOVE := 8.0
const TAP_TIME := 450

var _touches := {}
var _pinch_dist := 0.0
var _pinch_mid := Vector2.ZERO
var _tap_valid := false
var _tap_start := Vector2.ZERO
var _tap_time := 0
var _drag_mouse := false
var _left_down := false
var _left_start := Vector2.ZERO


func _ready() -> void:
	position_smoothing_enabled = false
	reset_view()
	get_viewport().size_changed.connect(_clamp)


func reset_view() -> void:
	position = Vector2(World.W * World.T, World.H * World.T) * 0.5
	zoom = Vector2.ONE * _min_zoom()
	_clamp()


func _world_rect() -> Rect2:
	var f := float(World.FRAME)
	return Rect2(-f, -f, World.W * World.T + 2.0 * f, World.H * World.T + 2.0 * f)


func _min_zoom() -> float:
	var vp := get_viewport_rect().size
	var wr := _world_rect()
	return minf(vp.x / wr.size.x, vp.y / wr.size.y)


func screen_to_world(p: Vector2) -> Vector2:
	var vp := get_viewport_rect().size
	return position + (p - vp * 0.5) / zoom.x


func _set_zoom_at(z: float, screen_p: Vector2) -> void:
	var before := screen_to_world(screen_p)
	z = clampf(z, _min_zoom(), MAX_ZOOM)
	zoom = Vector2(z, z)
	var vp := get_viewport_rect().size
	position = before - (screen_p - vp * 0.5) / z
	_clamp()


func _clamp() -> void:
	var vp := get_viewport_rect().size
	if zoom.x < _min_zoom():
		zoom = Vector2.ONE * _min_zoom()
	var view := vp / zoom.x
	var wr := _world_rect()
	var p := position
	for a in 2:
		if view[a] >= wr.size[a]:
			p[a] = wr.position[a] + wr.size[a] * 0.5
		else:
			p[a] = clampf(p[a], wr.position[a] + view[a] * 0.5, wr.end[a] - view[a] * 0.5)
	position = p


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		_on_touch(e)
	elif e is InputEventScreenDrag:
		_on_drag(e)
	elif e is InputEventMouseButton:
		_on_mouse_button(e)
	elif e is InputEventMouseMotion:
		if _drag_mouse:
			position -= e.relative / zoom.x
			_clamp()


# ---------------------------------------------------------------- Touch

func _on_touch(e: InputEventScreenTouch) -> void:
	if e.pressed:
		_touches[e.index] = e.position
		if _touches.size() == 1:
			_tap_valid = true
			_tap_start = e.position
			_tap_time = Time.get_ticks_msec()
		else:
			_tap_valid = false
			_start_pinch()
	else:
		_touches.erase(e.index)
		if _tap_valid and _touches.is_empty() and e.position.distance_to(_tap_start) < TAP_MOVE \
				and Time.get_ticks_msec() - _tap_time < TAP_TIME:
			tapped.emit(screen_to_world(e.position))
		_tap_valid = false
		if _touches.size() >= 2:
			_start_pinch()


func _on_drag(e: InputEventScreenDrag) -> void:
	_touches[e.index] = e.position
	if _tap_valid and e.position.distance_to(_tap_start) > TAP_MOVE:
		_tap_valid = false
	if _touches.size() >= 2:
		_update_pinch()


func _two_points() -> Array:
	var keys := _touches.keys()
	keys.sort()
	return [_touches[keys[0]], _touches[keys[1]]]


func _start_pinch() -> void:
	var p := _two_points()
	_pinch_dist = maxf(1.0, p[0].distance_to(p[1]))
	_pinch_mid = (p[0] + p[1]) * 0.5


func _update_pinch() -> void:
	var p := _two_points()
	var dist := maxf(1.0, p[0].distance_to(p[1]))
	var mid: Vector2 = (p[0] + p[1]) * 0.5
	# Punkt unter der alten Fingermitte bleibt unter der neuen Fingermitte
	var anchor := screen_to_world(_pinch_mid)
	var z := clampf(zoom.x * dist / _pinch_dist, _min_zoom(), MAX_ZOOM)
	zoom = Vector2(z, z)
	var vp := get_viewport_rect().size
	position = anchor - (mid - vp * 0.5) / z
	_clamp()
	_pinch_dist = dist
	_pinch_mid = mid


# ---------------------------------------------------------------- Maus

func _on_mouse_button(e: InputEventMouseButton) -> void:
	match e.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			if e.pressed:
				_set_zoom_at(zoom.x * 1.15, e.position)
		MOUSE_BUTTON_WHEEL_DOWN:
			if e.pressed:
				_set_zoom_at(zoom.x / 1.15, e.position)
		MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
			_drag_mouse = e.pressed
		MOUSE_BUTTON_LEFT:
			if e.pressed:
				_left_down = true
				_left_start = e.position
			elif _left_down:
				_left_down = false
				if e.position.distance_to(_left_start) < TAP_MOVE:
					tapped.emit(screen_to_world(e.position))
