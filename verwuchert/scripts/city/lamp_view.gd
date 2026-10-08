class_name LampView
extends Node2D
## Straßenlaterne am Gehweg. Der Lichtkegel am Boden kommt von der Lichtebene.

var builder: Node
var _glow: Node2D


func setup(pos: Vector2, city_builder: Node) -> void:
	position = pos
	builder = city_builder
	use_parent_material = true
	_glow = Node2D.new()
	_glow.set_script(preload("res://scripts/city/lamp_glow.gd"))
	add_child(_glow)
	_glow.builder = builder


func _draw() -> void:
	draw_rect(Rect2(-1, 0, 3, 1), Pal.SLATE)
	draw_rect(Rect2(0, -15, 1, 15), Pal.STONE_D)
	draw_rect(Rect2(-1, -1, 1, 1), Pal.STONE_D)
	draw_rect(Rect2(0, -16, 4, 1), Pal.STONE_D)
	draw_rect(Rect2(3, -15, 2, 1), Pal.NIGHT)
	draw_rect(Rect2(3, -14, 2, 1), Pal.YELLOW)
