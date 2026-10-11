class_name AntFont
extends RefCounted
## Kleine 3x5-Pixelschrift. Jeder Buchstabe wird Pixel für Pixel gezeichnet.

const GLYPH_H := 5
const ADVANCE := 4

const GLYPHS := {
	"A": [".#.", "#.#", "###", "#.#", "#.#"],
	"B": ["##.", "#.#", "##.", "#.#", "##."],
	"C": [".##", "#..", "#..", "#..", ".##"],
	"D": ["##.", "#.#", "#.#", "#.#", "##."],
	"E": ["###", "#..", "##.", "#..", "###"],
	"F": ["###", "#..", "##.", "#..", "#.."],
	"G": [".##", "#..", "#.#", "#.#", ".##"],
	"H": ["#.#", "#.#", "###", "#.#", "#.#"],
	"I": ["###", ".#.", ".#.", ".#.", "###"],
	"J": ["..#", "..#", "..#", "#.#", ".#."],
	"K": ["#.#", "#.#", "##.", "#.#", "#.#"],
	"L": ["#..", "#..", "#..", "#..", "###"],
	"M": ["#.#", "###", "###", "#.#", "#.#"],
	"N": ["##.", "#.#", "#.#", "#.#", "#.#"],
	"O": [".#.", "#.#", "#.#", "#.#", ".#."],
	"P": ["##.", "#.#", "##.", "#..", "#.."],
	"Q": [".#.", "#.#", "#.#", "##.", ".##"],
	"R": ["##.", "#.#", "##.", "#.#", "#.#"],
	"S": [".##", "#..", ".#.", "..#", "##."],
	"T": ["###", ".#.", ".#.", ".#.", ".#."],
	"U": ["#.#", "#.#", "#.#", "#.#", "###"],
	"V": ["#.#", "#.#", "#.#", "#.#", ".#."],
	"W": ["#.#", "#.#", "###", "###", "#.#"],
	"X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
	"Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
	"Z": ["###", "..#", ".#.", "#..", "###"],
	"Ä": ["#.#", ".#.", "#.#", "###", "#.#"],
	"Ö": ["#.#", ".#.", "#.#", "#.#", ".#."],
	"Ü": ["#.#", "...", "#.#", "#.#", "###"],
	"0": ["###", "#.#", "#.#", "#.#", "###"],
	"1": [".#.", "##.", ".#.", ".#.", "###"],
	"2": ["##.", "..#", ".#.", "#..", "###"],
	"3": ["##.", "..#", ".#.", "..#", "##."],
	"4": ["#.#", "#.#", "###", "..#", "..#"],
	"5": ["###", "#..", "##.", "..#", "##."],
	"6": [".##", "#..", "###", "#.#", "###"],
	"7": ["###", "..#", ".#.", ".#.", ".#."],
	"8": ["###", "#.#", "###", "#.#", "###"],
	"9": ["###", "#.#", "###", "..#", "##."],
	"-": ["...", "...", "###", "...", "..."],
	".": ["...", "...", "...", "...", ".#."],
	":": ["...", ".#.", "...", ".#.", "..."],
	"!": [".#.", ".#.", ".#.", "...", ".#."],
	"+": ["...", ".#.", "###", ".#.", "..."],
	"/": ["..#", "..#", ".#.", "#..", "#.."],
	"%": ["#.#", "..#", ".#.", "#..", "#.#"],
}

static var _cache := {}


static func _pixels(ch: String) -> PackedVector2Array:
	if _cache.has(ch):
		return _cache[ch]
	var out := PackedVector2Array()
	var rows: Array = GLYPHS.get(ch, [])
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "#":
				out.append(Vector2(x, y))
	_cache[ch] = out
	return out


static func text_width(text: String, scale := 1) -> int:
	if text.is_empty():
		return 0
	return (text.length() * ADVANCE - 1) * scale


static func draw_text(ci: CanvasItem, pos: Vector2, text: String, color: Color, scale := 1) -> void:
	var x := floorf(pos.x)
	var y := floorf(pos.y)
	for ch in text.to_upper():
		for p in _pixels(ch):
			ci.draw_rect(Rect2(x + p.x * scale, y + p.y * scale, scale, scale), color)
		x += ADVANCE * scale


static func draw_text_shadow(ci: CanvasItem, pos: Vector2, text: String, color: Color, shadow: Color, scale := 1) -> void:
	draw_text(ci, pos + Vector2(scale, scale), text, shadow, scale)
	draw_text(ci, pos, text, color, scale)


static func draw_text_centered(ci: CanvasItem, center_x: float, y: float, text: String, color: Color, scale := 1) -> void:
	draw_text(ci, Vector2(roundf(center_x - text_width(text, scale) * 0.5), y), text, color, scale)
