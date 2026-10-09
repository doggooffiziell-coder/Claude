class_name PhaseStrip
extends Control
## Drei Karten im Hauptmenü: die drei Phasen des Spiels. Die ersten beiden sind spielbar.

const CARDS := [
	{"icon": "house", "title": "1 Stadtbau", "sub": "etwa 8 Min.", "open": true},
	{"icon": "years", "title": "2 Zeitraffer", "sub": "50 Jahre, 1 Min.", "open": true},
	{"icon": "bunker", "title": "3 Bunker", "sub": "bald, 30 Tage", "open": false},
]
const CARD_W := 104
const GAP := 6
const CARD_H := 42

var _font: Font
var _t := 0.0


func _ready() -> void:
	_font = PixelFont.font()
	custom_minimum_size = Vector2(CARD_W * 3 + GAP * 2, CARD_H)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for i in CARDS.size():
		var c: Dictionary = CARDS[i]
		var r := Rect2(i * (CARD_W + GAP), 0, CARD_W, CARD_H)
		var open: bool = c.open
		draw_rect(r.grow(1), Pal.BLACK)
		draw_rect(r, Pal.a(Pal.NIGHT, 0.92))
		draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 1)), Pal.SLATE if open else Pal.a(Pal.SLATE, 0.5))
		var pulse := 1.0 if (open and fposmod(_t, 2.0) < 1.2) else 0.65
		var border := Pal.a(Pal.OCHRE, pulse) if open else Pal.STONE_D
		draw_rect(r, border, false, 1.0)
		var icon: Texture2D = IconArt.get_icon(c.icon)
		draw_texture(icon, r.position + Vector2(5, 10), Color(1, 1, 1, 1.0 if open else 0.4))
		var tcol := Pal.YELLOW if open else Pal.STONE_L
		draw_string(_font, r.position + Vector2(32, 17), c.title, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE, tcol)
		draw_string(_font, r.position + Vector2(32, 29), c.sub, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE, Pal.STONE if not open else Pal.BONE)
		if open:
			var glow := 0.5 + 0.5 * sin(_t * 4.0)
			draw_rect(Rect2(r.end.x - 8, r.position.y + 4, 3, 3), Pal.a(Pal.LEAF_L, 0.5 + glow * 0.5))
