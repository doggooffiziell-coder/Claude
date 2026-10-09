class_name TimelapseBar
extends Control
## Zeitleiste von Jahr 0 bis Jahr 50. Kleine Rauten zeigen, wann etwas passiert ist oder passieren wird.

var progress := 0.0
var years := 50.0
var marks: Array = []


func _draw() -> void:
	var w := size.x
	var y := roundf(size.y * 0.5) + 2.0
	draw_rect(Rect2(0, y, w, 3), Pal.SLATE)
	draw_rect(Rect2(0, y, roundf(w * clampf(progress, 0.0, 1.0)), 3), Pal.YELLOW)
	draw_rect(Rect2(0, y + 1, roundf(w * clampf(progress, 0.0, 1.0)), 1), Pal.OCHRE)
	var font := PixelFont.font()
	for k in range(0, int(years) + 1, 10):
		var x := roundf(w * float(k) / years)
		x = clampf(x, 0.0, w - 1.0)
		draw_rect(Rect2(x, y + 4, 1, 2), Pal.STONE)
		var txt := str(k)
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE).x
		draw_string(font, Vector2(clampf(x - tw * 0.5, 0.0, w - tw), y + 15), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE, Pal.STONE_L)
	for m in marks:
		var x2 := clampf(roundf(w * float(m) / years), 1.0, w - 2.0)
		var done := float(m) / years <= progress
		var col := Pal.BONE if done else Pal.STONE
		draw_rect(Rect2(x2, y - 4, 1, 3), col)
		draw_rect(Rect2(x2 - 1, y - 3, 3, 1), col)
	var px := clampf(roundf(w * clampf(progress, 0.0, 1.0)), 1.0, w - 2.0)
	draw_rect(Rect2(px - 1, y - 2, 3, 7), Pal.WHITE)
