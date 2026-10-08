class_name CarView
extends Node2D
## Ein Auto. gpos liegt auf der Fahrspur in Feldern, die Position folgt in Iso.

var builder: Node
var body := Pal.BRICK
var tile := Vector2i.ZERO
var next_tile := Vector2i.ZERO
var dir := Vector2i(1, 0)
var face := 0
var gpos := Vector2.ZERO
var target := Vector2.ZERO
var moving := true
var speed_mult := 1.0
var _lights: Node2D


func setup(city_builder: Node, color: Color) -> void:
	builder = city_builder
	body = color
	speed_mult = randf_range(0.85, 1.15)
	use_parent_material = true
	_lights = Node2D.new()
	_lights.set_script(preload("res://scripts/city/car_lights.gd"))
	add_child(_lights)
	_lights.car = self


func sync() -> void:
	position = Iso.to_screen(gpos.x, gpos.y).round()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var art := VehicleArt.car(face, body)
	var off: Vector2 = -art.anchor
	var bump := 0.0
	if moving and builder and int(builder.anim_time * 8.0 + position.x) % 7 == 0:
		bump = -1.0
	draw_texture(art.tex, off + Vector2(0, bump))
