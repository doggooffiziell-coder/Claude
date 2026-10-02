class_name Background
extends Node2D
## Dark room, back wall panels and the ceiling lamp.

const W := World.W
const H := World.H
const LAMP_X := 192
const COL_ROOM := Color("222226")
const COL_PANEL := Color("27272c")
const COL_SEAM := Color("1b1b1f")
const COL_CEIL := Color("17171a")
const COL_BASE := Color("2f2f35")


func _draw() -> void:
	var floor_y := World.FLOOR_Y
	draw_rect(Rect2(0, 0, W, floor_y), COL_ROOM)
	# Wall panels with seams and a subtle highlight edge.
	for x in range(0, W, 48):
		draw_rect(Rect2(x + 2, 10, 44, floor_y - 18), COL_PANEL)
		draw_rect(Rect2(x, 8, 1, floor_y - 8), COL_SEAM)
		draw_rect(Rect2(x + 1, 8, 1, floor_y - 8), Color("2b2b31"))
	for y in range(40, floor_y - 8, 40):
		draw_rect(Rect2(0, y, W, 1), COL_SEAM)
	draw_rect(Rect2(0, 0, W, 8), COL_CEIL)
	draw_rect(Rect2(0, 8, W, 1), Color("101012"))
	draw_rect(Rect2(0, floor_y - 6, W, 6), COL_BASE)
	draw_rect(Rect2(0, floor_y - 6, W, 1), Color("3a3a41"))
	_draw_lamp()


func _draw_lamp() -> void:
	var x := LAMP_X
	# Cord
	draw_rect(Rect2(x, 0, 1, 13), Color("0e0e10"))
	draw_rect(Rect2(x - 1, 8, 3, 2), Color("0e0e10"))
	# Shade: a stepped trapezoid with a dark outline and a light top edge.
	var rows := [[2, 13], [3, 14], [4, 15], [5, 16], [6, 17], [8, 18], [9, 19]]
	for r in rows:
		var half: int = r[0]
		var y: int = r[1]
		draw_rect(Rect2(x - half - 1, y, half * 2 + 3, 1), Color("0e0e10"))
		draw_rect(Rect2(x - half, y, half * 2 + 1, 1), Color("4a4a52"))
	draw_rect(Rect2(x - 2, 13, 5, 1), Color("6a6a74"))
	draw_rect(Rect2(x - 9, 19, 19, 1), Color("33333a"))
	# Bulb
	draw_rect(Rect2(x - 2, 20, 5, 2), Color("fff2c8"))
	draw_rect(Rect2(x - 1, 22, 3, 1), Color("ffe6a0"))
