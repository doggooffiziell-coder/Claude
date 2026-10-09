class_name TimelapseHud
extends Control
## Anzeige im Zeitraffer: Jahreszähler mit Jahreszeit, Zeitleiste mit Ereignissen, Chronik, Knopf zum
## Überspringen und am Ende die Zusammenfassung. Alles hängt an Ankern und passt sich jeder Bildgröße an.

signal skip_pressed
signal continue_pressed
signal again_pressed
signal menu_pressed

const CHRONICLE_LINES := 3

var _phone := false
var _year_label: Label
var _season_label: Label
var _timeline: TimelapseBar
var _skip: Button
var _chron_box: VBoxContainer
var _chron_panel: PanelContainer
var _end: CenterContainer
var _end_title: Label
var _end_body: Label
var _load: Control
var _load_fill: ColorRect
var _load_label: Label
var _lines: Array[Dictionary] = []


func _ready() -> void:
	_phone = Platform.phone
	theme = UiTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top()
	_build_chronicle()
	_build_end()
	_build_loader()


func _build_top() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.custom_minimum_size = Vector2(78, 0)
	row.add_child(col)
	_year_label = Label.new()
	_year_label.text = "Jahr 0"
	_year_label.add_theme_font_size_override("font_size", PixelFont.SIZE * 2)
	_year_label.add_theme_color_override("font_color", Pal.YELLOW)
	col.add_child(_year_label)
	_season_label = Label.new()
	_season_label.text = "Sommer"
	col.add_child(_season_label)
	_timeline = TimelapseBar.new()
	_timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_timeline.custom_minimum_size = Vector2(80, 26)
	row.add_child(_timeline)
	_skip = Button.new()
	_skip.text = "Überspringen"
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.custom_minimum_size = Vector2(96 if _phone else 84, 26 if _phone else 22)
	_skip.pressed.connect(func(): skip_pressed.emit())
	row.add_child(_skip)


func _build_chronicle() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 6)
	add_child(margin)
	_chron_panel = PanelContainer.new()
	_chron_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chron_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_chron_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	_chron_panel.modulate.a = 0.0
	margin.add_child(_chron_panel)
	_chron_box = VBoxContainer.new()
	_chron_box.add_theme_constant_override("separation", 1)
	_chron_panel.add_child(_chron_box)


func _build_end() -> void:
	_end = CenterContainer.new()
	_end.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end.visible = false
	add_child(_end)
	var panel := PanelContainer.new()
	_end.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	col.custom_minimum_size = Vector2(300, 0)
	panel.add_child(col)
	_end_title = Label.new()
	_end_title.add_theme_font_size_override("font_size", PixelFont.SIZE * 2)
	_end_title.add_theme_color_override("font_color", Pal.YELLOW)
	col.add_child(_end_title)
	_end_body = Label.new()
	_end_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_end_body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	col.add_child(row)
	for spec in [["Weiter", "continue"], ["Nochmal", "again"], ["Menü", "menu"]]:
		var b := Button.new()
		b.text = spec[0]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(90 if _phone else 78, 26 if _phone else 20)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_emit_button.bind(str(spec[1])))
		row.add_child(b)


func _emit_button(id: String) -> void:
	if id == "continue":
		continue_pressed.emit()
	elif id == "again":
		again_pressed.emit()
	else:
		menu_pressed.emit()


func _build_loader() -> void:
	_load = Control.new()
	_load.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_load)
	var bg := ColorRect.new()
	bg.color = Pal.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load.add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	center.add_child(col)
	var title := Label.new()
	title.text = "Die Zeit vergeht"
	title.add_theme_font_size_override("font_size", PixelFont.SIZE * 2)
	title.add_theme_color_override("font_color", Pal.YELLOW)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	_load_label = Label.new()
	_load_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_load_label)
	var track := ColorRect.new()
	track.color = Pal.SLATE
	track.custom_minimum_size = Vector2(160, 4)
	col.add_child(track)
	_load_fill = ColorRect.new()
	_load_fill.color = Pal.YELLOW
	_load_fill.size = Vector2(0, 4)
	track.add_child(_load_fill)


# Aufrufe von außen

func set_loading(progress: float, text: String) -> void:
	_load_fill.size.x = 160.0 * clampf(progress, 0.0, 1.0)
	_load_label.text = text


func loaded() -> void:
	_load.visible = false


func set_events(list: Array, years: float) -> void:
	_timeline.years = years
	_timeline.marks = list.map(func(e): return float(e.year))
	_timeline.queue_redraw()


func set_year(year: float, years: float, season: String) -> void:
	_year_label.text = "Jahr %d" % int(floor(year + 0.001))
	_season_label.text = season
	_timeline.progress = year / years
	_timeline.queue_redraw()


func push_event(year: float, text: String) -> void:
	var l := Label.new()
	l.text = "Jahr %d  %s" % [int(year), text]
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(290, 0)
	_chron_box.add_child(l)
	_lines.append({"label": l, "age": 0.0})
	while _lines.size() > CHRONICLE_LINES:
		var old: Dictionary = _lines.pop_front()
		old.label.queue_free()
	_chron_panel.modulate.a = 1.0
	_chron_panel.reset_size()


func set_skip_text(text: String) -> void:
	_skip.text = text


func show_end(year: int, text: String) -> void:
	_end_title.text = "Jahr %d" % year
	_end_body.text = text
	_end.visible = true
	_skip.visible = false
	_chron_panel.visible = false


func _process(delta: float) -> void:
	# Ältere Zeilen der Chronik verblassen
	for i in _lines.size():
		var d: Dictionary = _lines[_lines.size() - 1 - i]
		d.age = float(d.age) + delta
		var a := 1.0 if i == 0 else (0.62 if i == 1 else 0.38)
		d.label.modulate.a = a
	if not _lines.is_empty():
		var newest: Dictionary = _lines[_lines.size() - 1]
		if float(newest.age) > 9.0:
			_chron_panel.modulate.a = maxf(0.0, _chron_panel.modulate.a - delta * 0.6)
