class_name UiTheme
extends RefCounted
## Theme für alle Menüs: Pixel-Schrift, Rahmen und Knöpfe als 9-Patch aus Code.

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = PixelFont.font()
	t.default_font_size = PixelFont.SIZE

	t.set_stylebox("panel", "Panel", panel_box())
	t.set_stylebox("panel", "PanelContainer", panel_box())

	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(state, "Button", button_box(state))
	t.set_color("font_color", "Button", Pal.BONE)
	t.set_color("font_hover_color", "Button", Pal.WHITE)
	t.set_color("font_pressed_color", "Button", Pal.YELLOW)
	t.set_color("font_focus_color", "Button", Pal.BONE)
	t.set_color("font_disabled_color", "Button", Pal.STONE_D)
	t.set_color("font_hover_pressed_color", "Button", Pal.YELLOW)
	t.set_constant("h_separation", "Button", 3)

	t.set_color("font_color", "Label", Pal.BONE)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0))
	t.set_constant("line_spacing", "Label", 2)

	var tip := panel_box()
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", Pal.BONE)
	t.set_font("font", "TooltipLabel", PixelFont.font())
	t.set_font_size("font_size", "TooltipLabel", PixelFont.SIZE)
	_theme = t
	return t


static func _box_from(c: PixelCanvas, margin: int, pad: Vector4i) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = c.texture()
	sb.texture_margin_left = margin
	sb.texture_margin_top = margin
	sb.texture_margin_right = margin
	sb.texture_margin_bottom = margin
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return sb


## Dunkle Tafel mit hellem Innenrand oben links.
static func panel_box(fill: Color = Pal.NIGHT) -> StyleBoxTexture:
	var c := PixelCanvas.new(12, 12)
	c.rect(1, 0, 10, 12, Pal.BLACK)
	c.rect(0, 1, 12, 10, Pal.BLACK)
	c.rect(1, 1, 10, 10, Pal.STONE_D)
	c.rect(2, 2, 8, 8, fill)
	c.hline(2, 2, 8, Shade.light(fill))
	c.px(1, 1, Pal.BLACK)
	c.px(10, 1, Pal.BLACK)
	c.px(1, 10, Pal.BLACK)
	c.px(10, 10, Pal.BLACK)
	c.hline(2, 1, 8, Pal.STONE)
	return _box_from(c, 4, Vector4i(6, 5, 6, 5))


static func button_box(state: String, accent: Color = Pal.OCHRE) -> StyleBoxTexture:
	var c := PixelCanvas.new(12, 12)
	var fill := Pal.SLATE
	var top := Pal.STONE_D
	var shift := 0
	match state:
		"hover":
			fill = Pal.STONE_D
			top = Pal.STONE
		"pressed":
			fill = Pal.NIGHT
			top = Pal.BLACK
			shift = 1
		"disabled":
			fill = Pal.NIGHT
			top = Pal.SLATE
		"selected":
			fill = Pal.STONE_D
			top = Pal.STONE
		"focus":
			var f := PixelCanvas.new(12, 12)
			return _box_from(f, 4, Vector4i(5, 4, 5, 5))
	c.rect(1, shift, 10, 11 - shift, Pal.BLACK)
	c.rect(0, 1 + shift, 12, 9 - shift, Pal.BLACK)
	c.rect(1, 1 + shift, 10, 9 - shift, fill)
	c.hline(1, 1 + shift, 10, top)
	if shift == 0:
		c.hline(1, 10, 10, Pal.BLACK)
		c.hline(1, 9, 10, Shade.dark(fill))
	if state == "selected":
		c.frame(0, 0, 12, 12, accent)
		c.px(0, 0, Color(0, 0, 0, 0))
		c.px(11, 0, Color(0, 0, 0, 0))
		c.px(0, 11, Color(0, 0, 0, 0))
		c.px(11, 11, Color(0, 0, 0, 0))
		c.img.set_pixel(0, 0, Color(0, 0, 0, 0))
		c.img.set_pixel(11, 0, Color(0, 0, 0, 0))
		c.img.set_pixel(0, 11, Color(0, 0, 0, 0))
		c.img.set_pixel(11, 11, Color(0, 0, 0, 0))
	return _box_from(c, 4, Vector4i(5, 4 + shift, 5, 5 - shift))


## Kleiner Fortschrittsbalken als Bild: gefüllt, leer.
static func bar_colors(value: float) -> Color:
	if value > 0.6:
		return Pal.GRASS_L
	if value > 0.3:
		return Pal.OCHRE
	return Pal.BRICK_L
