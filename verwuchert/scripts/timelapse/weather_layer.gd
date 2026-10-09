class_name WeatherLayer
extends Node2D
## Regen, Schnee und fallendes Laub in Bildschirmpixeln. Liegt über der Welt und unter der Anzeige.
## Es gibt feste Plätze für Teilchen, die Stärke bestimmt nur, wie viele davon sichtbar sind.

const RAIN := 150
const SNOW := 110
const LEAVES := 36

var rain := 0.0
var snow := 0.0
var leaves := 0.0
var wind := 1.0
var _size := Vector2(640, 360)
var _t := 0.0
var _seeds: Array[Vector3] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in RAIN + SNOW + LEAVES:
		_seeds.append(Vector3(rng.randf(), rng.randf(), rng.randf()))
	z_index = 5


func set_levels(r: float, s: float, l: float) -> void:
	rain = r
	snow = s
	leaves = l
	visible = r > 0.01 or s > 0.01 or l > 0.01
	if visible:
		queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	var vp := get_viewport()
	if vp != null:
		_size = vp.get_visible_rect().size
	if visible:
		queue_redraw()


func _draw() -> void:
	var n := int(rain * RAIN)
	for i in n:
		var s := _seeds[i]
		var x := fposmod(s.x * _size.x + _t * 60.0 * wind, _size.x + 40.0) - 20.0
		var y := fposmod(s.y * _size.y + _t * (190.0 + s.z * 60.0), _size.y + 10.0) - 5.0
		var p := Vector2(roundf(x), roundf(y))
		draw_rect(Rect2(p, Vector2(1, 3)), Pal.a(Pal.SKY, 0.55))
		draw_rect(Rect2(p + Vector2(-1, 3), Vector2(1, 1)), Pal.a(Pal.WHITE, 0.35))
	var m := int(snow * SNOW)
	for i in m:
		var s := _seeds[RAIN + i]
		var sway := sin(_t * (0.8 + s.z) + s.x * 9.0) * 6.0
		var x := fposmod(s.x * _size.x + _t * 8.0 * wind + sway, _size.x)
		var y := fposmod(s.y * _size.y + _t * (22.0 + s.z * 18.0), _size.y)
		var big := s.z > 0.7
		draw_rect(Rect2(roundf(x), roundf(y), 2 if big else 1, 2 if big else 1), Pal.a(Pal.WHITE, 0.9))
	var k := int(leaves * LEAVES)
	var cols := [Pal.OCHRE, Pal.BRICK_L, Pal.RUST, Pal.YELLOW, Pal.LEAF_L]
	for i in k:
		var s := _seeds[RAIN + SNOW + i]
		var sway := sin(_t * (1.2 + s.z) + s.y * 7.0) * 10.0
		var x := fposmod(s.x * _size.x + _t * 26.0 * wind + sway, _size.x)
		var y := fposmod(s.y * _size.y + _t * (24.0 + s.z * 16.0), _size.y)
		draw_rect(Rect2(roundf(x), roundf(y), 2, 1), cols[int(s.z * 5.0) % 5])
