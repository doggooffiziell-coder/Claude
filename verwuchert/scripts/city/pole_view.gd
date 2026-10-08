class_name PoleView
extends Node2D
## Holzmast mit Querträger und Laterne. Steht nur an Straßen mit Strom.
## Die Leitungen zwischen den Masten zeichnet WireLayer.

const HEIGHT := 22

var builder: Node
var ground_pos := Vector2.ZERO
var tile := Vector2i.ZERO
var _glow: Node2D


func setup(g: Vector2, t: Vector2i, city_builder: Node) -> void:
	ground_pos = g
	tile = t
	builder = city_builder
	position = Iso.to_screen(g.x, g.y).round()
	use_parent_material = true
	_glow = Node2D.new()
	_glow.set_script(preload("res://scripts/city/pole_glow.gd"))
	add_child(_glow)
	_glow.builder = builder


## Spitze des Masts in Weltkoordinaten, dort hängen die Leitungen.
func top() -> Vector2:
	return position + Vector2(0, -HEIGHT + 1)


func _draw() -> void:
	draw_rect(Rect2(-1, -1, 3, 2), Pal.a(Pal.BLACK, 0.3))
	draw_rect(Rect2(0, -HEIGHT, 1, HEIGHT), Pal.WOOD)
	draw_rect(Rect2(1, -HEIGHT, 1, HEIGHT), Pal.SOIL)
	# Querträger mit Isolatoren
	draw_rect(Rect2(-3, -HEIGHT + 2, 8, 1), Pal.WOOD)
	draw_rect(Rect2(-3, -HEIGHT + 1, 1, 1), Pal.BONE)
	draw_rect(Rect2(4, -HEIGHT + 1, 1, 1), Pal.BONE)
	# Laternenarm und Leuchte
	draw_rect(Rect2(2, -14, 3, 1), Pal.STONE_D)
	draw_rect(Rect2(4, -13, 2, 1), Pal.NIGHT)
	draw_rect(Rect2(4, -12, 2, 1), Pal.YELLOW)
