class_name CityHud
extends Control
## Oberfläche für Phase 1: Geld und Zeit oben, Werkzeuge unten, Infotafel rechts, Dialoge.

var builder: CityBuilder

var _money: Label
var _money_delta: Label
var _people: Label
var _crews: Label
var _power: Label
var _water: Label
var _chron_box: VBoxContainer
var _chron_labels: Array[Label] = []
var _clock: Label
var _clock_icon: TextureRect
var _timer: Label
var _payday_bar: ColorRect
var _speed_buttons: Array[Button] = []
var _tool_buttons := {}
var _tip_panel: PanelContainer
var _tip_title: Label
var _tip_body: Label
var _info_panel: PanelContainer
var _info_title: Label
var _info_body: Label
var _toast: Label
var _toast_t := 0.0
var _hint: Label
var _dialog: Control
var _menu: Control
var _hover_tool := ""
var _money_shown := 0.0
var _delta_t := 0.0
var _phone := false
var _speed_cycle: Button
var _zoom_btn: Button
var _menu_btn: Button
var _sb_speed := {}
var _last_speed := -1
var _tip_id := "~"
var _info_t := 0.0
var _color_cache := {}


func setup(city_builder: CityBuilder) -> void:
	builder = city_builder
	_phone = Platform.phone
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top_bar()
	_build_toolbar()
	_build_tip()
	_build_info()
	_build_toast()
	_build_dialog()
	_build_menu()
	builder.toast.connect(show_toast)
	builder.selection_changed.connect(_on_selection)
	builder.payday.connect(_on_payday)
	builder.chronicle_added.connect(func(_e): _refresh_chronicle())
	_money_shown = float(GameState.city.money)
	get_viewport().size_changed.connect(_layout)
	_layout()
	if _phone:
		show_toast("Bau deine Stadt. Zwei Finger bewegen die Karte.", Pal.BONE)
	else:
		show_toast("Bau deine Stadt. Häuser brauchen Straße, Strom und Wasser.", Pal.BONE)


## Setzt die Schriftfarbe nur, wenn sie sich ändert. Jeder Aufruf löst sonst eine Neuberechnung aus.
func _tint(n: Control, col: Color) -> void:
	var id := n.get_instance_id()
	if _color_cache.get(id) == col:
		return
	_color_cache[id] = col
	n.add_theme_color_override("font_color", col)


## Ordnet alles neu, wenn sich die Bildgröße ändert. Das Handy hat ein breiteres Bild.
func _layout() -> void:
	var vp := Platform.view_size()
	if _info_panel != null:
		_info_panel.position = Vector2(vp.x - 156, 34 if _phone else 28)
	if _hint != null:
		_hint.position = Vector2(vp.x - 6 - 300, vp.y - (68 if _phone else 60))
	if _chron_box != null:
		# Die Chronik braucht links neben der Werkzeugleiste Platz
		_chron_box.visible = vp.x >= 690.0 or not _phone


func _icon(id: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = IconArt.get_icon(id)
	r.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	r.custom_minimum_size = Vector2(9, 9)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _label(text := "", col := Pal.BONE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _small_button(icon_id: String, tip: String) -> Button:
	var b := Button.new()
	b.icon = IconArt.get_icon(icon_id)
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(26, 24) if _phone else Vector2(17, 17)
	b.add_theme_constant_override("h_separation", 0)
	for s in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(s, _tight(UiTheme.button_box(s)))
	return b


func _tight(sb: StyleBoxTexture) -> StyleBoxTexture:
	var c := sb.duplicate() as StyleBoxTexture
	c.content_margin_left = 3
	c.content_margin_right = 3
	c.content_margin_top = 3 + (1 if sb.content_margin_top > 4 else 0)
	c.content_margin_bottom = 4 - (1 if sb.content_margin_top > 4 else 0)
	return c


# Obere Leiste

func _build_top_bar() -> void:
	if _phone:
		_build_top_bar_phone()
		return
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 23
	var sb := UiTheme.panel_box()
	sb.content_margin_top = 4
	sb.content_margin_bottom = 3
	bar.add_theme_stylebox_override("panel", sb)
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	bar.add_child(row)

	row.add_child(_icon("coin"))
	var money_box := VBoxContainer.new()
	money_box.add_theme_constant_override("separation", 0)
	_money = _label("0", Pal.YELLOW)
	_money.custom_minimum_size = Vector2(38, 0)
	money_box.add_child(_money)
	row.add_child(money_box)
	_money_delta = _label("", Pal.LEAF_L)
	_money_delta.custom_minimum_size = Vector2(30, 0)
	row.add_child(_money_delta)
	# Zahltag-Balken
	var pd_holder := Control.new()
	pd_holder.custom_minimum_size = Vector2(22, 9)
	pd_holder.tooltip_text = "Zahltag"
	var pd_bg := ColorRect.new()
	pd_bg.color = Pal.BLACK
	pd_bg.position = Vector2(0, 3)
	pd_bg.size = Vector2(22, 4)
	pd_holder.add_child(pd_bg)
	_payday_bar = ColorRect.new()
	_payday_bar.color = Pal.OCHRE
	_payday_bar.position = Vector2(1, 4)
	_payday_bar.size = Vector2(0, 2)
	pd_holder.add_child(_payday_bar)
	row.add_child(pd_holder)
	row.add_child(_sep())

	row.add_child(_icon("people"))
	_people = _label("0")
	_people.custom_minimum_size = Vector2(18, 0)
	row.add_child(_people)
	row.add_child(_sep())
	row.add_child(_icon("crew"))
	_crews = _label("0/2")
	_crews.custom_minimum_size = Vector2(34, 0)
	row.add_child(_crews)
	row.add_child(_sep())
	row.add_child(_icon("bolt"))
	_power = _label("0/0")
	_power.custom_minimum_size = Vector2(30, 0)
	_power.tooltip_text = "Strom: versorgte Gebäude / Leistung"
	_power.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(_power)
	row.add_child(_icon("drop"))
	_water = _label("0/0")
	_water.custom_minimum_size = Vector2(30, 0)
	_water.tooltip_text = "Wasser: versorgte Häuser / Leistung"
	_water.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(_water)
	row.add_child(_sep())
	_clock_icon = _icon("sun")
	row.add_child(_clock_icon)
	_clock = _label("Tag 1  08:00")
	row.add_child(_clock)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)

	_timer = _label("00:00", Pal.STONE_L)
	_timer.tooltip_text = "Bauzeit der Stadt"
	_timer.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(_timer)
	var ids := ["pause", "play1", "play2", "play3"]
	var tips := ["Pause (Leertaste)", "Normal", "Doppelt", "Dreifach"]
	for i in ids.size():
		var b := _small_button(ids[i], tips[i])
		b.pressed.connect(builder.set_speed.bind(i))
		row.add_child(b)
		_speed_buttons.append(b)
	var save := _small_button("save", "Speichern (F5)")
	save.pressed.connect(func():
		if GameState.save_game():
			show_toast("Gespeichert.", Pal.LEAF_L))
	row.add_child(save)
	var done := Button.new()
	done.text = "Stadt fertig"
	done.focus_mode = Control.FOCUS_NONE
	done.add_theme_color_override("font_color", Pal.YELLOW)
	for s in ["normal", "hover", "pressed"]:
		done.add_theme_stylebox_override(s, _tight(UiTheme.button_box(s)))
	done.pressed.connect(_ask_finish)
	row.add_child(done)


## Schlanke Leiste fürs Handy: weniger Angaben, dafür große Knöpfe. Geschwindigkeit hat einen
## einzigen Knopf, der durchzählt. Speichern steckt im Pausenmenü.
func _build_top_bar_phone() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	var sb := UiTheme.panel_box()
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	bar.add_theme_stylebox_override("panel", sb)
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	bar.add_child(row)
	row.add_child(_icon("coin"))
	_money = _label("0", Pal.YELLOW)
	_money.custom_minimum_size = Vector2(40, 0)
	row.add_child(_money)
	_money_delta = _label("", Pal.LEAF_L)
	var pd_holder := Control.new()
	pd_holder.custom_minimum_size = Vector2(22, 9)
	var pd_bg := ColorRect.new()
	pd_bg.color = Pal.BLACK
	pd_bg.position = Vector2(0, 3)
	pd_bg.size = Vector2(22, 4)
	pd_holder.add_child(pd_bg)
	_payday_bar = ColorRect.new()
	_payday_bar.color = Pal.OCHRE
	_payday_bar.position = Vector2(1, 4)
	_payday_bar.size = Vector2(0, 2)
	pd_holder.add_child(_payday_bar)
	row.add_child(pd_holder)
	row.add_child(_sep())
	row.add_child(_icon("people"))
	_people = _label("0")
	_people.custom_minimum_size = Vector2(18, 0)
	row.add_child(_people)
	row.add_child(_sep())
	row.add_child(_icon("crew"))
	_crews = _label("0/2")
	_crews.custom_minimum_size = Vector2(34, 0)
	row.add_child(_crews)
	row.add_child(_sep())
	row.add_child(_icon("bolt"))
	_power = _label("0/0")
	_power.custom_minimum_size = Vector2(30, 0)
	row.add_child(_power)
	row.add_child(_icon("drop"))
	_water = _label("0/0")
	_water.custom_minimum_size = Vector2(30, 0)
	row.add_child(_water)
	row.add_child(_sep())
	_clock_icon = _icon("sun")
	row.add_child(_clock_icon)
	_clock = _label("Tag 1  08:00")
	row.add_child(_clock)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	_timer = _label("00:00", Pal.STONE_L)
	row.add_child(_timer)
	_speed_cycle = _small_button("play1", "Tempo")
	_speed_cycle.pressed.connect(func(): builder.set_speed((builder.speed_index + 1) % 4))
	row.add_child(_speed_cycle)
	_zoom_btn = _small_button("zoom", "Zoom")
	_zoom_btn.pressed.connect(func(): builder.zoom_toggle())
	row.add_child(_zoom_btn)
	_menu_btn = _small_button("menu", "Menü")
	_menu_btn.pressed.connect(_open_menu)
	row.add_child(_menu_btn)
	var done := Button.new()
	done.text = "Stadt fertig"
	done.focus_mode = Control.FOCUS_NONE
	done.custom_minimum_size = Vector2(0, 24)
	done.add_theme_color_override("font_color", Pal.YELLOW)
	for st in ["normal", "hover", "pressed"]:
		done.add_theme_stylebox_override(st, _tight(UiTheme.button_box(st)))
	done.pressed.connect(_ask_finish)
	row.add_child(done)


func _sep() -> Control:
	var c := ColorRect.new()
	c.color = Pal.STONE_D
	c.custom_minimum_size = Vector2(1, 9)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


# Werkzeugleiste

func _build_toolbar() -> void:
	var holder := CenterContainer.new()
	holder.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	holder.offset_top = -58 if _phone else -50
	holder.offset_bottom = -1
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	var bar := PanelContainer.new()
	var sb := UiTheme.panel_box()
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	sb.content_margin_top = 5
	sb.content_margin_bottom = 4
	bar.add_theme_stylebox_override("panel", sb)
	holder.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	bar.add_child(row)
	var tools: Array = BuildingTypes.ORDER.duplicate()
	tools.append("demolish")
	for i in tools.size():
		var id: String = tools[i]
		if id == "demolish":
			row.add_child(_sep_tall())
		var b := Button.new()
		b.icon = IconArt.get_icon(id)
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(44, 46) if _phone else Vector2(36, 38)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.text = str(BuildingTypes.cost(id)) if id != "demolish" else "Abriss"
		b.add_theme_color_override("font_color", Pal.YELLOW if id != "demolish" else Pal.ROSE)
		b.add_theme_color_override("font_pressed_color", Pal.WHITE)
		b.add_theme_color_override("font_hover_pressed_color", Pal.WHITE)
		var sel := UiTheme.button_box("selected", Pal.OCHRE)
		b.add_theme_stylebox_override("pressed", sel)
		b.add_theme_stylebox_override("hover_pressed", sel)
		for s in ["normal", "hover", "disabled"]:
			var st := UiTheme.button_box(s).duplicate() as StyleBoxTexture
			st.content_margin_top = 3
			st.content_margin_bottom = 3
			b.add_theme_stylebox_override(s, st)
		sel.content_margin_top = 3
		sel.content_margin_bottom = 3
		b.pressed.connect(_on_tool.bind(id))
		b.mouse_entered.connect(func(): _hover_tool = id)
		b.mouse_exited.connect(func():
			if _hover_tool == id:
				_hover_tool = "")
		row.add_child(b)
		_tool_buttons[id] = b
		# Tastenkürzel als kleine Zahl
		var key := _label(str(i + 1) if id != "demolish" else "X", Pal.STONE)
		key.position = Vector2(2, 1)
		b.add_child(key)
	_hint = _label("", Pal.STONE_L)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.position = Vector2(640 - 6 - 300, 360 - 60)  # _layout() setzt die endgültige Stelle
	_hint.add_theme_color_override("font_shadow_color", Pal.BLACK)
	_hint.add_theme_constant_override("shadow_offset_x", 1)
	_hint.add_theme_constant_override("shadow_offset_y", 1)
	_hint.size = Vector2(300, 10)
	add_child(_hint)
	_build_chronicle()


## Chronik: die letzten Ereignisse der Stadt, unten links.
func _build_chronicle() -> void:
	_chron_box = VBoxContainer.new()
	_chron_box.add_theme_constant_override("separation", 1)
	_chron_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_chron_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_chron_box.offset_left = 4
	_chron_box.offset_bottom = -4
	_chron_box.custom_minimum_size = Vector2(146, 0)
	_chron_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_chron_box)
	var head := _label("Chronik", Pal.OCHRE)
	head.add_theme_color_override("font_shadow_color", Pal.BLACK)
	head.add_theme_constant_override("shadow_offset_x", 1)
	head.add_theme_constant_override("shadow_offset_y", 1)
	_chron_box.add_child(head)
	for i in 3:
		var l := _label("", Pal.BONE)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(146, 0)
		l.add_theme_constant_override("line_spacing", 1)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Pal.a(Pal.BLACK, 0.55)
		sb.content_margin_left = 3
		sb.content_margin_right = 3
		sb.content_margin_top = 1
		sb.content_margin_bottom = 1
		l.add_theme_stylebox_override("normal", sb)
		_chron_box.add_child(l)
		_chron_labels.append(l)
	_refresh_chronicle()


func _refresh_chronicle() -> void:
	var list: Array = GameState.city.get("chronicle", [])
	var n := _chron_labels.size()
	for i in n:
		var idx := list.size() - n + i
		var l := _chron_labels[i]
		if idx < 0:
			l.visible = false
			continue
		var e: Dictionary = list[idx]
		l.visible = true
		l.text = e.text
		l.modulate.a = 0.45 + 0.55 * float(i + 1) / n


func _sep_tall() -> Control:
	var c := ColorRect.new()
	c.color = Pal.STONE_D
	c.custom_minimum_size = Vector2(1, 34)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _on_tool(id: String) -> void:
	builder.select_tool(id)


# Tooltip über der Leiste

func _build_tip() -> void:
	_tip_panel = PanelContainer.new()
	_tip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_panel.visible = false
	add_child(_tip_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	_tip_panel.add_child(col)
	_tip_title = _label("", Pal.YELLOW)
	col.add_child(_tip_title)
	_tip_body = _label("", Pal.BONE)
	_tip_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_body.custom_minimum_size = Vector2(200, 0)
	col.add_child(_tip_body)


func _update_tip() -> void:
	# Auf dem Handy gibt es kein Schweben, die Hinweise gehören immer zum gewählten Werkzeug
	var id := builder.tool if _phone else (_hover_tool if _hover_tool != "" else builder.tool)
	if id != _tip_id:
		_tip_id = id
		_rebuild_tip(id)
	var vp := Platform.view_size()
	if id != "" and _tip_panel.visible:
		var btn: Button = _tool_buttons.get(id)
		var x := 6.0
		if btn:
			x = clampf(btn.global_position.x + btn.size.x * 0.5 - _tip_panel.size.x * 0.5, 4.0, vp.x - _tip_panel.size.x - 4.0)
		_tip_panel.position = Vector2(roundf(x), vp.y - (62 if _phone else 52) - _tip_panel.size.y)


func _rebuild_tip(id: String) -> void:
	if id == "":
		_tip_panel.visible = false
		return
	_tip_panel.visible = true
	if id == "demolish":
		_tip_title.text = "Abreißen"
		_tip_body.text = "Fertige Gebäude bringen die Hälfte zurück, Baustellen alles.\nZiehen reißt mehrere ab. Bäume kosten %d." % Config.integer("city/tree_clear_cost", 5)
	else:
		var info := BuildingTypes.info(id)
		_tip_title.text = "%s   %d" % [info.name, BuildingTypes.cost(id)]
		var lines: Array[String] = [info.desc]
		var bt := BuildingTypes.build_time(id)
		lines.append("Bauzeit: %s" % ("sofort" if bt < 1.0 else "%d s" % int(bt)))
		if info.needs != "":
			lines.append("Braucht: %s" % info.needs)
		var cfg := Config.building(id)
		if cfg.has("capacity"):
			var what := "Gebäude mit Strom" if id == "power_plant" else "Häuser mit Wasser"
			lines.append("Versorgt %d %s, über die Straßen." % [int(cfg.capacity), what])
		if cfg.has("radius"):
			lines.append("Wirkt %d Felder weit." % int(cfg.radius))
		if cfg.has("upkeep"):
			lines.append("Unterhalt: %d pro Zahltag" % int(cfg.upkeep))
		_tip_body.text = "\n".join(lines)
	_tip_panel.reset_size()


# Infotafel

func _build_info() -> void:
	_info_panel = PanelContainer.new()
	_info_panel.visible = false
	_info_panel.position = Vector2(640 - 156, 28)  # _layout() setzt die endgültige Stelle
	_info_panel.custom_minimum_size = Vector2(150, 0)
	add_child(_info_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	_info_panel.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	_info_title = _label("", Pal.YELLOW)
	_info_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_info_title)
	var close := _small_button("close", "Schließen")
	close.pressed.connect(func(): builder.cancel())
	head.add_child(close)
	_info_body = _label("")
	_info_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_body.custom_minimum_size = Vector2(138, 0)
	col.add_child(_info_body)


func _on_selection(b: Dictionary) -> void:
	_info_panel.visible = not b.is_empty()


func _update_info() -> void:
	var b: Dictionary = builder.selected
	if b.is_empty():
		_info_panel.visible = false
		return
	var v: BuildingView = builder.building_views.get(int(b.id))
	var st: Dictionary = v.status if v else {}
	_info_title.text = str(b.get("name", BuildingTypes.display_name(b.type)))
	var lines: Array[String] = []
	if b.has("family"):
		_info_title.text = "Familie %s" % b.family
		lines.append(", ".join(b.get("people", [])))
	var addr: String = builder.address(b)
	if addr != "":
		lines.append(addr)
	if b.has("name") or b.has("family"):
		lines.append(BuildingTypes.display_name(b.type))
	lines.append("Material: %s" % BuildingTypes.MATERIAL_NAMES.get(b.material, b.material))
	lines.append("Zustand: %d %%" % int(b.condition))
	match b.state:
		"queued":
			lines.append("Wartet auf einen Bautrupp.")
		"building":
			lines.append("Im Bau: %d %%" % int(float(b.progress) * 100.0))
		_:
			match b.type:
				"house":
					if st.get("occupied", false):
						lines.append("Bewohnt von %d Leuten." % int(Config.building("house").get("residents", 4)))
					else:
						lines.append("Leer. Es fehlt: %s." % _needs_text(st))
						lines.append("Grundsteuer: +%d" % int(Config.building("house").get("base_tax", 6)))
					if st.get("parks", 0) > 0:
						lines.append("Park in der Nähe: +%d" % (int(st.parks) * int(Config.building("house").get("park_bonus", 4))))
					if st.get("polluted", false):
						lines.append("Rauch der Fabrik stört.")
				"shop":
					if st.get("active", false):
						lines.append("Kunden aus %d Häusern." % int(st.get("customers", 0)))
					else:
						lines.append("Geschlossen. Es fehlt: %s." % _needs_text(st))
				"factory":
					lines.append("Läuft." if st.get("active", false) else "Steht still. Es fehlt: %s." % _needs_text(st))
				"water_tower":
					lines.append("Versorgt %d von %d Häusern." % [builder.water_load, builder.water_cap] if st.get("active", false) else "Braucht eine Straße.")
				"power_plant":
					lines.append("Versorgt %d von %d Plätzen." % [builder.power_load, builder.power_cap] if st.get("active", false) else "Braucht eine Straße.")
				"park":
					lines.append("Häuser in der Nähe zahlen mehr.")
			var inc: int = st.get("income", 0)
			if inc != 0:
				lines.append("Pro Zahltag: %s%d" % ["+" if inc > 0 else "", inc])
	if not b.contents.is_empty():
		lines.append("")
		lines.append("Inhalt:")
		for item in b.contents:
			lines.append("  %d %s" % [int(b.contents[item]), BuildingTypes.ITEM_NAMES.get(item, item)])
	_info_body.text = "\n".join(lines)
	_info_panel.reset_size()


func _needs_text(st: Dictionary) -> String:
	var parts: Array[String] = []
	for n in st.get("needs", []):
		match n:
			"road_need": parts.append("Straße")
			"bolt": parts.append("Strom")
			"drop": parts.append("Wasser")
			"people_need": parts.append("Kunden")
	return ", ".join(parts) if not parts.is_empty() else "nichts"


# Meldungen

func _build_toast() -> void:
	_toast = _label("", Pal.BONE)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 30
	_toast.offset_bottom = 44
	var sb := StyleBoxFlat.new()
	sb.bg_color = Pal.a(Pal.BLACK, 0.7)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	_toast.add_theme_stylebox_override("normal", sb)
	_toast.modulate.a = 0.0
	add_child(_toast)


func show_toast(text: String, col: Color) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", col)
	_toast_t = 3.2
	# Schmal und mittig
	var w := PixelFont.font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE).x + 14
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -roundf(w * 0.5)
	_toast.offset_right = roundf(w * 0.5)
	_toast.offset_top = 30
	_toast.offset_bottom = 43


func _on_payday(net: int) -> void:
	_money_delta.text = ("+%d" % net) if net >= 0 else str(net)
	_money_delta.add_theme_color_override("font_color", Pal.LEAF_L if net >= 0 else Pal.ROSE)
	_delta_t = 2.5


# Dialoge

func _build_dialog() -> void:
	_dialog = _modal("Stadt fertig?", "Danach vergehen %d Jahre. Die Natur holt sich alles zurück.\nDu kannst nichts mehr bauen." % Config.integer("phase2/years", 50),
		[["Weiterbauen", func(): _dialog.visible = false, Pal.BONE], ["Jahre vergehen lassen", func(): builder.finish_city(), Pal.YELLOW]])


func _build_menu() -> void:
	_menu = _modal("Pause", "Verwuchert %s" % GameState.version(),
		[["Weiter", func(): _close_menu(), Pal.BONE],
		["Speichern", func():
			if GameState.save_game():
				show_toast("Gespeichert.", Pal.LEAF_L)
			_close_menu(), Pal.BONE],
		["Hauptmenü", func():
			GameState.save_game()
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn"), Pal.ROSE]])


var _speed_before := 1


func _open_menu() -> void:
	_speed_before = builder.speed_index
	builder.set_speed(0)
	_menu.visible = true


func _close_menu() -> void:
	_menu.visible = false
	builder.set_speed(_speed_before)


func _modal(title: String, text: String, buttons: Array) -> Control:
	var shade := ColorRect.new()
	shade.color = Pal.a(Pal.BLACK, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.visible = false
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var panel := PanelContainer.new()
	var sb := UiTheme.panel_box()
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var t := _label(title, Pal.YELLOW)
	t.add_theme_font_size_override("font_size", PixelFont.SIZE * 2)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	var body := _label(text)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	col.add_child(row)
	for b in buttons:
		var btn := Button.new()
		btn.text = b[0]
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(90, 26) if _phone else Vector2(70, 18)
		btn.add_theme_color_override("font_color", b[2])
		btn.pressed.connect(b[1])
		row.add_child(btn)
	return shade


func _ask_finish() -> void:
	_dialog.visible = true


func _unhandled_key_input(event: InputEvent) -> void:
	if builder == null:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _dialog.visible:
			_dialog.visible = false
		elif _menu.visible:
			_close_menu()
		elif not builder.cancel():
			_open_menu()
		get_viewport().set_input_as_handled()


# Laufende Anzeige

func _process(delta: float) -> void:
	if builder == null:
		return
	var c: Dictionary = GameState.city
	_money_shown = lerpf(_money_shown, float(c.money), minf(1.0, delta * 8.0))
	if absf(_money_shown - float(c.money)) < 1.0:
		_money_shown = float(c.money)
	_money.text = _fmt(int(round(_money_shown)))
	_tint(_money, Pal.YELLOW if int(c.money) >= 0 else Pal.ROSE)
	_delta_t -= delta
	_money_delta.modulate.a = clampf(_delta_t, 0.0, 1.0)
	var pd := Config.num("city/payday_seconds", 15.0)
	_payday_bar.size.x = roundf(20.0 * float(c.payday_timer) / pd)
	_people.text = str(builder.residents)
	var crews := Config.integer("city/crews", 2)
	var q := builder.queue_length()
	_crews.text = "%d/%d%s" % [builder.crews_busy(), crews, (" +%d" % q) if q > 0 else ""]
	_tint(_crews, Pal.OCHRE if q > 0 else Pal.BONE)
	_power.text = "%d/%d" % [builder.power_load, builder.power_cap]
	_tint(_power, Pal.ROSE if builder.power_cap == 0 or builder.power_load >= builder.power_cap else Pal.BONE)
	_water.text = "%d/%d" % [builder.water_load, builder.water_cap]
	_tint(_water, Pal.ROSE if builder.water_cap == 0 or builder.water_load >= builder.water_cap else Pal.BONE)
	_clock.text = "Tag %d  %s" % [int(c.day), DayCycle.clock_text(builder.hour)]
	var icon_id := "moon" if builder.night > 0.5 else "sun"
	if _clock_icon.get_meta("icon", "") != icon_id:
		_clock_icon.set_meta("icon", icon_id)
		_clock_icon.texture = IconArt.get_icon(icon_id)
	var left := builder.time_left()
	if left >= 0.0 and left <= 60.0:
		_timer.text = "Noch %s" % _mmss(left)
		_tint(_timer, Pal.ROSE if fposmod(builder.anim_time, 1.0) < 0.5 else Pal.BONE)
	else:
		_timer.text = _mmss(float(c.time))
		_tint(_timer, Pal.YELLOW if float(c.time) >= Config.num("city/target_seconds", 480) else Pal.STONE_L)
	if builder.speed_index != _last_speed:
		_last_speed = builder.speed_index
		_apply_speed_style()
	for id in _tool_buttons:
		var b: Button = _tool_buttons[id]
		var want: bool = builder.tool == id
		if b.button_pressed != want:
			b.set_pressed_no_signal(want)
		if id != "demolish":
			var dis: bool = BuildingTypes.cost(id) > int(c.money) and builder.tool != id
			if b.disabled != dis:
				b.disabled = dis
	_update_tip()
	_info_t -= delta
	if _info_t <= 0.0:
		_info_t = 0.25
		_update_info()
	_update_hint()
	_toast_t -= delta
	_toast.modulate.a = clampf(_toast_t / 0.4, 0.0, 1.0)


## Das Aussehen der Tempo-Knöpfe ändert sich nur, wenn das Tempo wechselt. Die Stile werden einmal gebaut.
func _apply_speed_style() -> void:
	if _sb_speed.is_empty():
		_sb_speed["normal"] = _tight(UiTheme.button_box("normal"))
		_sb_speed["selected"] = _tight(UiTheme.button_box("selected"))
	for i in _speed_buttons.size():
		var on: bool = i == builder.speed_index
		_speed_buttons[i].modulate = Color.WHITE if on else Color(0.6, 0.6, 0.65)
		_speed_buttons[i].add_theme_stylebox_override("normal", _sb_speed["selected" if on else "normal"])
	if _speed_cycle != null:
		_speed_cycle.icon = IconArt.get_icon(["pause", "play1", "play2", "play3"][builder.speed_index])
		_speed_cycle.add_theme_stylebox_override("normal", _sb_speed["selected" if builder.speed_index > 0 else "normal"])


func _update_hint() -> void:
	var t := builder.tool
	if _menu.visible or _dialog.visible:
		_hint.text = ""
		return
	if _phone:
		match t:
			"":
				_hint.text = "Tippen wählt. Ziehen bewegt. Zwei Finger zoomen."
			"road":
				_hint.text = "Ziehen und loslassen baut eine Straße."
			"demolish":
				_hint.text = "Loslassen reißt das Ziel ab."
			_:
				_hint.text = "Finger ziehen, loslassen baut."
		_hint.visible = not _tip_panel.visible
		return
	match t:
		"":
			_hint.text = "Klick: ansehen   Ziehen: Karte bewegen   Rad: Zoom"
		"road":
			_hint.text = "Ziehen baut eine Straße   Rechtsklick: abbrechen"
		"demolish":
			_hint.text = "Klick oder ziehen reißt ab   Rechtsklick: abbrechen"
		_:
			_hint.text = "Klick baut   Ziehen baut mehrere   Rechtsklick: abbrechen" if t in CityBuilder.PAINT_TOOLS else "Klick baut   Rechtsklick: abbrechen"
	_hint.visible = not _tip_panel.visible


static func _fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


static func _mmss(sec: float) -> String:
	var s := int(sec)
	return "%02d:%02d" % [s / 60, s % 60]
