extends CanvasLayer
## Anzeige oben links: grünes Holzschild mit ANT POP. und Einwohnerzahl.
## Dazu Infos zu angetippten Kammern und Meldungen bei Ereignissen.

const CREAM := Color(0.94, 0.91, 0.78)
const BOARD := Color(0.14, 0.31, 0.21)
const BOARD_LIGHT := Color(0.29, 0.50, 0.36)
const BOARD_DARK := Color(0.09, 0.21, 0.14)
const ANT_ICON := [
	".#...#.",
	"..#.#..",
	"...#...",
	"#.###.#",
	".#.#.#.",
	"..###..",
	"#.###.#",
	"..###..",
	"...#...",
]

var main
var _info_title := ""
var _info_lines: Array = []
var _info_color := Color.WHITE
var _info_t := 0.0
var _banner := ""
var _banner_t := 0.0
var _redraw_t := 0.0
var _blink := 0.0

@onready var canvas: Control = $Canvas


func setup(m) -> void:
	main = m
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_hud)


func show_info(title: String, lines: Array, ch: int) -> void:
	_info_title = title
	_info_lines = lines
	_info_color = World.CHAMBER_COLORS[ch] if ch > 0 else CREAM
	_info_t = 5.0
	canvas.queue_redraw()


func hide_info() -> void:
	_info_t = 0.0
	canvas.queue_redraw()


func banner(text: String, time := 4.0) -> void:
	_banner = text
	_banner_t = time
	canvas.queue_redraw()


func tick(dt: float) -> void:
	_blink += dt
	_info_t = maxf(0.0, _info_t - dt)
	_banner_t = maxf(0.0, _banner_t - dt)
	_redraw_t -= dt
	if _redraw_t <= 0.0:
		_redraw_t = 0.2
		canvas.queue_redraw()


func _draw_hud() -> void:
	if main == null:
		return
	_draw_sign(Vector2(3, 3))
	var c = main.colony
	var line := "FUTTER %d  TAG %d" % [int(c.food), main.events.day]
	AntFont.draw_text_shadow(canvas, Vector2(5, 37), line, CREAM, Color(0, 0, 0, 0.6))
	if c.starving and fmod(_blink, 1.0) < 0.6:
		AntFont.draw_text_shadow(canvas, Vector2(5, 44), "HUNGER!", Color(1.0, 0.4, 0.3), Color(0, 0, 0, 0.6))
	if _banner_t > 0.0:
		_draw_banner()
	if _info_t > 0.0:
		_draw_info()


func _draw_sign(o: Vector2) -> void:
	var w := 74.0
	var h := 30.0
	var outer := PackedVector2Array([o + Vector2(7, 0), o + Vector2(w, 0), o + Vector2(w, h), o + Vector2(0, h), o + Vector2(0, 7)])
	var shadow := PackedVector2Array()
	for p in outer:
		shadow.append(p + Vector2(2, 2))
	canvas.draw_colored_polygon(shadow, Color(0, 0, 0, 0.35))
	canvas.draw_colored_polygon(outer, BOARD_LIGHT)
	var inner := PackedVector2Array([o + Vector2(7, 1), o + Vector2(w - 1, 1), o + Vector2(w - 1, h - 1), o + Vector2(1, h - 1), o + Vector2(1, 7)])
	canvas.draw_colored_polygon(inner, BOARD)
	# Holzmaserung
	for k in range(6, int(h) - 2, 6):
		canvas.draw_rect(Rect2(o.x + 2, o.y + k, w - 3, 1), BOARD_DARK)
		var off := float((k * 7) % 23)
		canvas.draw_rect(Rect2(o.x + 10 + off, o.y + k - 2, 8, 1), BOARD.lightened(0.06))
	canvas.draw_rect(Rect2(o.x + 1, o.y + h - 2, w - 2, 1), BOARD_DARK)
	# Nagel mit Ring
	var n := o + Vector2(6, 9)
	canvas.draw_rect(Rect2(n - Vector2(2, 2), Vector2(5, 5)), Color(0.75, 0.6, 0.25))
	canvas.draw_rect(Rect2(n - Vector2(1, 1), Vector2(3, 3)), Color(0.2, 0.18, 0.12))
	canvas.draw_rect(Rect2(n - Vector2(1, 1), Vector2(1, 1)), Color(1.0, 0.9, 0.55))
	# Text und Ameisen-Symbol
	AntFont.draw_text(canvas, o + Vector2(15, 5), "ANT POP.", CREAM)
	for y in ANT_ICON.size():
		var row: String = ANT_ICON[y]
		for x in row.length():
			if row[x] == "#":
				canvas.draw_rect(Rect2(o.x + 4 + x, o.y + 14 + y, 1, 1), Color(0.97, 0.95, 0.88))
	AntFont.draw_text(canvas, o + Vector2(16, 13), str(main.ants.count), CREAM, 2)


func _draw_banner() -> void:
	var vw := canvas.size.x
	var tw := AntFont.text_width(_banner)
	var r := Rect2(roundf(vw * 0.5 - tw * 0.5) - 4, 58, tw + 8, 11)
	canvas.draw_rect(r, Color(0.05, 0.12, 0.08, 0.85))
	canvas.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), BOARD_LIGHT)
	canvas.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), BOARD_LIGHT)
	var col := Color(1.0, 0.85, 0.35) if fmod(_blink, 0.8) < 0.5 else CREAM
	AntFont.draw_text_centered(canvas, vw * 0.5, 61, _banner, col)


func _draw_info() -> void:
	var vs := canvas.size
	var w := 150.0
	var h := 16.0 + _info_lines.size() * 7.0
	var r := Rect2(roundf((vs.x - w) * 0.5), roundf(vs.y - h - 10.0), w, h)
	canvas.draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.35))
	canvas.draw_rect(r, BOARD_LIGHT)
	canvas.draw_rect(r.grow(-1), BOARD)
	canvas.draw_rect(Rect2(r.position + Vector2(5, 5), Vector2(5, 5)), _info_color)
	canvas.draw_rect(Rect2(r.position + Vector2(5, 5), Vector2(5, 1)), _info_color.lightened(0.3))
	AntFont.draw_text(canvas, r.position + Vector2(14, 5), _info_title, CREAM)
	canvas.draw_rect(Rect2(r.position.x + 4, r.position.y + 12, w - 8, 1), BOARD_DARK)
	for k in _info_lines.size():
		AntFont.draw_text(canvas, r.position + Vector2(8, 15 + k * 7), str(_info_lines[k]), CREAM.darkened(0.08))
