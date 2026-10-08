extends Control
## Hauptmenü: Abendhimmel, kleine Häuserzeile, Ranken wachsen über den Titel.

const W := 640
const H := 360

var _backdrop: Node2D
var _continue: Button
var _t := 0.0


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop = Node2D.new()
	_backdrop.set_script(preload("res://scripts/ui/menu_backdrop.gd"))
	add_child(_backdrop)

	var col := VBoxContainer.new()
	col.position = Vector2(40, 130)
	col.custom_minimum_size = Vector2(120, 0)
	col.add_theme_constant_override("separation", 5)
	add_child(col)
	var new_btn := _button("Neues Spiel", Pal.YELLOW)
	new_btn.pressed.connect(_new_game)
	col.add_child(new_btn)
	_continue = _button("Weiterspielen", Pal.BONE)
	_continue.pressed.connect(func(): GameState.continue_game())
	_continue.disabled = not GameState.has_save()
	col.add_child(_continue)
	var quit := _button("Beenden", Pal.ROSE)
	quit.pressed.connect(func(): get_tree().quit())
	quit.visible = not OS.has_feature("web")
	col.add_child(quit)

	var ver := Label.new()
	ver.text = "Version %s" % GameState.version()
	ver.add_theme_color_override("font_color", Pal.STONE)
	ver.position = Vector2(W - 70, H - 14)
	add_child(ver)
	var hint := Label.new()
	hint.text = "Phase 1 von 3: Bau deine Stadt."
	hint.add_theme_color_override("font_color", Pal.STONE_L)
	hint.position = Vector2(40, 208)
	add_child(hint)


func _button(text: String, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(120, 20)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_color_override("font_color", col)
	return b


func _new_game() -> void:
	GameState.new_game()
	GameState.go_to_phase(1)


func _process(delta: float) -> void:
	_t += delta
	if GameState.user_args.has("shot") and _t > float(GameState.user_args.get("wait", "4")):
		get_viewport().get_texture().get_image().save_png(str(GameState.user_args.shot))
		get_tree().quit()
