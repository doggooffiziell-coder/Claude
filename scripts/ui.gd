class_name GameUI
extends Node2D
## Whole HUD drawn by hand: status panel, toolbar, cursor and blade trail.

enum { T_GRAB, T_WATER, T_BLADE, T_FIRE, T_ICE, T_DOLL, T_RESET }

const TOOL_NAMES := ["GREIFEN", "WASSER", "KLINGE", "FEUER", "EIS", "NEUE PUPPE", "RESET"]

const BTN := 16
const BTN_GAP := 3
const TOOLBAR_Y := World.H - 20

const PANEL := Rect2(308, 4, 72, 136)

const COL_PANEL := Color("16161a")
const COL_PANEL_EDGE := Color("3a3a42")
const COL_TEXT := Color("d8d8d0")
const COL_DIM := Color("4a4a52")
const COL_BAR_BG := Color("26262c")
const COL_TAG_OFF := Color("23232a")

const BARS := [
	["KO", Color("4ccf5a")],
	["BL", Color("c81e2c")],
	["PN", Color("f08a24")],
	["O2", Color("2ec8c0")],
	["HR", Color("e85a8a")],
]

const TAGS := [
	["OUT", Color("9a9aa2")],
	["BLEED", Color("d0202e")],
	["FIRE", Color("ff5a1e")],
	["CHOKE", Color("2ec8c0")],
	["AGONY", Color("f08a24")],
	["HEAL", Color("f0d838")],
	["BLADE", Color("c4ccd8")],
	["TORN", Color("f070b4")],
	["FROZEN", Color("80c0ff")],
]

## Front view pose for the mini silhouette, same point order as Doll.
const MINI := [
	Vector2(0, -12), Vector2(0, -8), Vector2(0, 0), Vector2(0, 3),
	Vector2(-5, -3), Vector2(-7, 2), Vector2(5, -3), Vector2(7, 2),
	Vector2(-2, 9), Vector2(-3, 15), Vector2(-5, 15),
	Vector2(2, 9), Vector2(3, 15), Vector2(5, 15),
]
const MINI_W := [2.0, 4.0, 4.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 1.0, 2.0, 2.0, 1.0]

## 8x8 tool icons. '#' main color, '+' accent color.
const ICONS := [
	["...#.#..", ".#.#.#.#", ".#.#.#.#", ".#######", "########", ".#######", "..#####.", "..#####."],
	["...##...", "...##...", "..####..", ".######.", ".#+####.", ".#+####.", ".######.", "..####.."],
	["......##", ".....###", "....###.", "...###..", "..###...", ".+##....", "++......", "+......."],
	["...#....", "...##...", "..###.#.", ".####.#.", ".######.", "##+++###", "#+++++##", ".#+++##."],
	["...#....", ".#.#.#..", "..###...", "#######.", "..###...", ".#.#.#..", "...#....", "........"],
	[".##.....", ".##...+.", "####.+++", ".##...+.", ".##.....", ".#.#....", ".#.#....", "........"],
	["..###.#.", ".#...##.", "#...###.", "#.......", "#......#", ".#....#.", "..####..", "........"],
]
const ICON_COLORS := [
	[Color("ecece6"), Color("ecece6")],
	[Color("3c82e6"), Color("b4d8ff")],
	[Color("c8ccd8"), Color("8c5a32")],
	[Color("f06e1e"), Color("ffdc50")],
	[Color("a0dcfa"), Color("a0dcfa")],
	[Color("ecece6"), Color("6ee66e")],
	[Color("e6c850"), Color("e6c850")],
]

var main: Node
var hover := -1


func toolbar_x() -> int:
	var total := ICONS.size() * BTN + (ICONS.size() - 1) * BTN_GAP
	return (World.W - total) / 2


func button_rect(idx: int) -> Rect2:
	return Rect2(toolbar_x() + idx * (BTN + BTN_GAP), TOOLBAR_Y, BTN, BTN)


func toolbar_hit(p: Vector2) -> int:
	for idx in ICONS.size():
		if button_rect(idx).grow(1).has_point(p):
			return idx
	return -1


func blocks_input(p: Vector2) -> bool:
	return toolbar_hit(p) >= 0 or PANEL.has_point(p)


# ---------------------------------------------------------------- helpers

func _round_rect(r: Rect2, col: Color) -> void:
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	var h := r.size.y
	draw_rect(Rect2(x + 2, y, w - 4, h), col)
	draw_rect(Rect2(x + 1, y + 1, w - 2, h - 2), col)
	draw_rect(Rect2(x, y + 2, w, h - 4), col)


func _framed(r: Rect2, fill: Color, edge: Color) -> void:
	_round_rect(r, edge)
	_round_rect(r.grow(-1), fill)


# ---------------------------------------------------------------- draw

func _draw() -> void:
	_draw_title()
	_draw_cursor()
	_draw_trail()
	var doll: Doll = main.selected_doll()
	_draw_panel(doll)
	_draw_toolbar()


func _draw_title() -> void:
	PixelFont.draw_text(self, Vector2(5, 12), "RAGPIT", Color("8a8a92"))
	PixelFont.draw_text(self, Vector2(5, 19), TOOL_NAMES[main.tool], COL_DIM)


func _draw_cursor() -> void:
	var m: Vector2 = main.mouse
	if blocks_input(m):
		return
	var col := Color(1, 1, 1, 0.35)
	match main.tool:
		T_WATER, T_FIRE, T_ICE:
			var r := 4.0 if main.tool != T_WATER else 2.0
			draw_arc(m.floor() + Vector2(0.5, 0.5), r, 0.0, TAU, 16, col, 1.0)
		T_BLADE:
			draw_rect(Rect2(m.floor(), Vector2.ONE), Color(1, 1, 1, 0.7))
		T_GRAB:
			var c := Color(1, 1, 1, 0.5)
			var p := m.floor()
			draw_rect(Rect2(p + Vector2(-3, 0), Vector2(2, 1)), c)
			draw_rect(Rect2(p + Vector2(2, 0), Vector2(2, 1)), c)
			draw_rect(Rect2(p + Vector2(0, -3), Vector2(1, 2)), c)
			draw_rect(Rect2(p + Vector2(0, 2), Vector2(1, 2)), c)


func _draw_trail() -> void:
	for seg in main.blade_trail:
		var a: float = 1.0 - seg[2] / 0.25
		if a > 0.0:
			draw_line(seg[0], seg[1], Color(0.95, 0.97, 1.0, a), 1.0)


func _draw_panel(doll: Doll) -> void:
	_framed(PANEL, COL_PANEL, COL_PANEL_EDGE)
	var px := PANEL.position.x
	var py := PANEL.position.y
	# Silhouette box
	var box := Rect2(px + 4, py + 4, 64, 36)
	draw_rect(box, Color("101013"))
	if doll == null:
		PixelFont.draw_text_centered(self, box.get_center().x, box.get_center().y - 2, "KEINE", COL_DIM)
		return
	PixelFont.draw_text(self, box.position + Vector2(2, 2), "P" + str(doll.doll_id), COL_DIM)
	_draw_mini(doll, box.get_center() + Vector2(0, 1))

	# Bars
	var values := [doll.ko, doll.bl, doll.pn, doll.o2, clampf(doll.hr / 1.6, 0.0, 100.0)]
	for idx in BARS.size():
		var y := py + 45 + idx * 7
		var bar := Rect2(px + 4, y, 50, 4)
		draw_rect(bar, COL_BAR_BG)
		var col: Color = BARS[idx][1]
		if idx == 4:
			col = col.lerp(Color.WHITE, doll.beat_flash * 0.5)
		var fill := roundf(bar.size.x * clampf(values[idx] / 100.0, 0.0, 1.0))
		if fill > 0:
			draw_rect(Rect2(bar.position, Vector2(fill, 4)), col)
			draw_rect(Rect2(bar.position, Vector2(fill, 1)), col.lightened(0.3))
		for nx in range(10, 50, 10):
			draw_rect(Rect2(bar.position.x + nx, y, 1, 4), Color(0, 0, 0, 0.35))
		PixelFont.draw_text(self, Vector2(px + 58, y - 0.0), BARS[idx][0], COL_TEXT)

	# Status tags
	var flags := doll.flags()
	for idx in TAGS.size():
		var col_i := idx % 2
		var row := idx / 2
		var r := Rect2(px + 4 + col_i * 33, py + 82 + row * 10, 31, 8)
		var tag_name: String = TAGS[idx][0]
		var on: bool = flags.get(tag_name, false)
		if on:
			var c: Color = TAGS[idx][1]
			_round_rect(r, c)
			draw_rect(Rect2(r.position.x + 2, r.position.y, r.size.x - 4, 1), c.lightened(0.35))
			PixelFont.draw_text_centered(self, r.get_center().x, r.position.y + 2, tag_name, Color("101012"))
		else:
			_round_rect(r, COL_TAG_OFF)
			PixelFont.draw_text_centered(self, r.get_center().x, r.position.y + 2, tag_name, COL_DIM)


func _draw_mini(doll: Doll, c: Vector2) -> void:
	var order := Doll.DRAW_ORDER
	for pass_i in 2:
		for k in order:
			var a: Vector2 = c + MINI[Doll.PART_A[k]]
			var b: Vector2 = c + MINI[Doll.PART_B[k]]
			var col: Color
			if pass_i == 0:
				col = Color("000000")
			elif not doll.is_attached(k):
				col = Color("3a3a40")
			else:
				col = Color("e6e6e0").lerp(Doll.COL_CHAR, clampf(doll.char_lvl[k], 0.0, 0.8))
				if doll.frozen:
					col = col.lerp(Doll.COL_ICE, 0.6)
			var grow := 1.0 if pass_i == 0 else 0.0
			if k == Doll.HEAD:
				draw_circle(b, 3.0 + grow, col)
			else:
				var w: float = MINI_W[k] + grow * 2.0
				draw_line(a, b, col, w)
				draw_circle(a, w * 0.5, col)
				draw_circle(b, w * 0.5, col)
	# Wounds as red dots on the matching spot.
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)
	for w in doll.wounds:
		var a: Vector2 = c + MINI[Doll.PART_A[w.part]]
		var b: Vector2 = c + MINI[Doll.PART_B[w.part]]
		var p: Vector2
		if w.part == Doll.HEAD:
			p = b + Vector2.from_angle(w.t * TAU) * 1.5
			if w.stump:
				p = a
		else:
			var d := (b - a).normalized()
			p = a.lerp(b, w.t) + d.orthogonal() * w.s * MINI_W[w.part] * 0.4
		var col := Color("ff2030").lerp(Color("ff8080"), pulse) if w.bleed > 0.0 else Color("6a1a1e")
		draw_rect(Rect2(p.floor(), Vector2.ONE * (2 if w.stump else 1)), col)


func _draw_toolbar() -> void:
	var x0 := toolbar_x()
	var total := ICONS.size() * BTN + (ICONS.size() - 1) * BTN_GAP
	_framed(Rect2(x0 - 3, TOOLBAR_Y - 3, total + 6, BTN + 6), Color("141418"), Color("3a3a42"))
	for idx in ICONS.size():
		var r := button_rect(idx)
		var selected: bool = idx == main.tool
		var bg := Color("2a2a30")
		var edge := Color("44444c")
		if selected:
			bg = Color("3c3c46")
			edge = Color("e6e6e0")
		elif idx == hover:
			bg = Color("33333a")
			edge = Color("6a6a74")
		_framed(r, bg, edge)
		var rows: Array = ICONS[idx]
		var main_col: Color = ICON_COLORS[idx][0]
		var acc_col: Color = ICON_COLORS[idx][1]
		for y in rows.size():
			var row: String = rows[y]
			for x in row.length():
				var ch := row[x]
				if ch == "#":
					draw_rect(Rect2(r.position.x + 4 + x, r.position.y + 4 + y, 1, 1), main_col)
				elif ch == "+":
					draw_rect(Rect2(r.position.x + 4 + x, r.position.y + 4 + y, 1, 1), acc_col)
	if hover >= 0:
		var label: String = TOOL_NAMES[hover] + "  " + str(hover + 1)
		var lw := PixelFont.text_width(label) + 6
		var lr := Rect2(roundf(World.W * 0.5 - lw * 0.5), TOOLBAR_Y - 13, lw, 9)
		_framed(lr, Color("141418"), Color("3a3a42"))
		PixelFont.draw_text_centered(self, World.W * 0.5, TOOLBAR_Y - 11, label, COL_TEXT)
