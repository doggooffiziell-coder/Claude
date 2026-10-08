class_name WalkerView
extends Node2D
## Ein Fußgänger. Läuft eine Liste von Punkten ab und verschwindet an der Zieltür.

const SKIN := [Pal.SAND, Pal.BRICK_L, Pal.WOOD_L, Pal.WOOD, Pal.ROSE]
const HAIR := [Pal.SOIL_D, Pal.SOIL, Pal.OCHRE, Pal.NIGHT, Pal.STONE_L, Pal.BRICK]
const SHIRT := [Pal.TEAL, Pal.BRICK_L, Pal.OCHRE, Pal.BLUE, Pal.MOSS, Pal.PLUM, Pal.BONE, Pal.ROSE]
const PANTS := [Pal.BLUE_D, Pal.SLATE, Pal.SOIL, Pal.STONE_D]

var builder: Node
## Wegpunkte in Feldern auf dem Boden.
var points: Array[Vector2] = []
var gpos := Vector2.ZERO
var idx := 1
var done := false
var skin: Color
var hair: Color
var shirt: Color
var pants: Color
var walk := 0.0
var speed := 12.0
var fade := 0.0


func setup(city_builder: Node, pts: Array[Vector2]) -> void:
	builder = city_builder
	points = pts
	gpos = pts[0]
	position = Iso.to_screen(gpos.x, gpos.y).round()
	use_parent_material = true
	skin = SKIN[randi() % SKIN.size()]
	hair = HAIR[randi() % HAIR.size()]
	shirt = SHIRT[randi() % SHIRT.size()]
	pants = PANTS[randi() % PANTS.size()]
	speed = randf_range(10.0, 14.0)
	modulate.a = 0.0


func advance(dt: float) -> void:
	if idx >= points.size():
		fade -= dt * 3.0
		modulate.a = clampf(fade, 0.0, 1.0)
		if fade <= 0.0:
			done = true
		return
	fade = minf(1.0, fade + dt * 3.0)
	modulate.a = fade
	var to := points[idx] - gpos
	var step := speed / 32.0 * dt
	walk += dt * speed * 0.5
	if to.length() <= step:
		gpos = points[idx]
		idx += 1
	else:
		gpos += to.normalized() * step
	position = Iso.to_screen(gpos.x, gpos.y).round()
	queue_redraw()


func _draw() -> void:
	var p := Vector2(-1, 0)
	var stepping := int(walk) % 2 == 0
	draw_rect(Rect2(p + Vector2(-1, 0), Vector2(5, 1)), Pal.a(Pal.BLACK, 0.25))
	# Beine
	if stepping:
		draw_rect(Rect2(p + Vector2(0, -2), Vector2(1, 2)), pants)
		draw_rect(Rect2(p + Vector2(2, -2), Vector2(1, 2)), pants)
	else:
		draw_rect(Rect2(p + Vector2(1, -2), Vector2(1, 2)), pants)
	draw_rect(Rect2(p + Vector2(0, -5), Vector2(3, 3)), shirt)
	draw_rect(Rect2(p + Vector2(0, -5), Vector2(1, 3)), Shade.light(shirt))
	draw_rect(Rect2(p + Vector2(0, -7), Vector2(3, 2)), skin)
	draw_rect(Rect2(p + Vector2(0, -8), Vector2(3, 1)), hair)
