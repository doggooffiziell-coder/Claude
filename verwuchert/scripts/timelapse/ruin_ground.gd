class_name RuinGround
extends Node2D
## Malt das Bodenbild als Raute. Das Material (Shader) liegt auf diesem Knoten, damit nur der Boden
## von Gras, Wasser und Schnee verändert wird und nicht die Erdkante.

var tex: Texture2D
var offset := Vector2.ZERO


func _draw() -> void:
	if tex == null:
		return
	draw_set_transform_matrix(Iso.GROUND)
	draw_texture(tex, offset)
