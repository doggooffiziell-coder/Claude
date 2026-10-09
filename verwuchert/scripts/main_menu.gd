extends Control
## Hauptmenü: isometrische Insel mit der laufenden Stadt, Blockschrift-Titel mit Tiefe,
## Menüpunkte, Phasenleiste, Anleitung, Einstellungen und Sicherheitsabfrage.

const W := 640
const H := 360

var backdrop: MenuBackdrop
var title: MenuTitle
var strip: PhaseStrip
var new_btn: Button
var continue_btn: Button
var continue_info: Label
var guide_btn: Button
var settings_btn: Button
var quit_btn: Button
var screens := {}
var screen := "main"

var _main_box: VBoxContainer
var _hover: Button
var _t := 0.0
var _wipe_armed := false
var _wipe_btn: Button
var _setting_buttons := {}
var _version: Label


func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop = MenuBackdrop.new()
	add_child(backdrop)
	title = MenuTitle.new()
	title.position = Vector2(26, 20)
	add_child(title)
	_build_main()
	strip = PhaseStrip.new()
	add_child(strip)
	_version = Label.new()
	_version.text = "Version %s" % GameState.version()
	_version.add_theme_color_override("font_color", Pal.STONE)
	add_child(_version)
	screens["guide"] = _build_guide()
	screens["settings"] = _build_settings()
	screens["confirm"] = _build_confirm()
	for k in screens:
		add_child(screens[k])
	refresh()
	get_viewport().size_changed.connect(_layout)
	_layout()
	var want: String = str(GameState.user_args.get("screen", ""))
	if want != "":
		show_screen(want)


## Ordnet die Teile nach der Größe des Bildes. Das Handy hat ein breiteres, kürzeres Bild.
func _layout() -> void:
	var vp := Platform.view_size()
	_version.position = Vector2(vp.x - 70, vp.y - 14)
	strip.position = Vector2(24, vp.y - 62)
	strip.visible = vp.y >= 300.0


# Hauptseite

func _build_main() -> void:
	_main_box = VBoxContainer.new()
	_main_box.position = Vector2(30, 98)
	_main_box.add_theme_constant_override("separation", 5)
	add_child(_main_box)
	new_btn = _button("Neues Spiel", Pal.YELLOW)
	new_btn.pressed.connect(_on_new)
	_main_box.add_child(new_btn)
	var cont := VBoxContainer.new()
	cont.add_theme_constant_override("separation", 1)
	continue_btn = _button("Weiterspielen", Pal.BONE)
	continue_btn.pressed.connect(func(): GameState.continue_game())
	cont.add_child(continue_btn)
	continue_info = Label.new()
	continue_info.add_theme_color_override("font_color", Pal.STONE_L)
	continue_info.custom_minimum_size = Vector2(150, 0)
	cont.add_child(continue_info)
	_main_box.add_child(cont)
	guide_btn = _button("Anleitung", Pal.BONE)
	guide_btn.pressed.connect(show_screen.bind("guide"))
	_main_box.add_child(guide_btn)
	settings_btn = _button("Einstellungen", Pal.BONE)
	settings_btn.pressed.connect(show_screen.bind("settings"))
	_main_box.add_child(settings_btn)
	quit_btn = _button("Beenden", Pal.ROSE)
	quit_btn.pressed.connect(func(): get_tree().quit())
	quit_btn.visible = not OS.has_feature("web")
	_main_box.add_child(quit_btn)


func _button(text: String, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(132, 24 if Platform.phone else 20)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_color_override("font_color", col)
	b.mouse_entered.connect(func(): _hover = b)
	b.mouse_exited.connect(func():
		if _hover == b:
			_hover = null)
	return b


## Aktualisiert Angaben, die vom Spielstand abhängen.
func refresh() -> void:
	var info := GameState.peek_save()
	continue_btn.disabled = info.is_empty()
	if info.is_empty():
		continue_info.text = "Noch kein Spielstand"
	else:
		var fam := int(info.families)
		if int(info.get("phase", 1)) == 2:
			continue_info.text = "Stadt fertig, die Zeit wartet"
		elif int(info.get("phase", 1)) >= 3:
			continue_info.text = "Die Ruinen warten"
		else:
			continue_info.text = "Tag %d, %d %s, %s" % [int(info.day), fam, "Familie" if fam == 1 else "Familien", CityHud._fmt(int(info.money))]
	if _wipe_btn != null:
		_wipe_btn.disabled = info.is_empty()
		_wipe_armed = false
		_wipe_btn.text = "Spielstand löschen"
	for key in _setting_buttons:
		_setting_buttons[key].text = _setting_text(key)


func show_screen(name: String) -> void:
	screen = name
	for k in screens:
		screens[k].visible = k == name
	_main_box.visible = name == "main" or name == "confirm"
	refresh()


func _on_new() -> void:
	if GameState.has_save():
		show_screen("confirm")
	else:
		_start_new()


func _start_new() -> void:
	GameState.new_game()
	GameState.go_to_phase(1)


# Anleitung

func _build_guide() -> Control:
	var shade := _shade()
	var panel := _panel(shade, 560)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	col.add_child(_title_label("So spielst du"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	col.add_child(row)
	var phases := [
		["house", "Phase 1", "Stadt bauen", Pal.YELLOW, "Baue Straßen, Häuser, Läden und Fabriken. Häuser brauchen Strom und Wasser über die Straße. Leere Häuser zahlen eine kleine Grundsteuer."],
		["years", "Phase 2", "50 Jahre", Pal.LEAF_L, "Die Zeit rast. Gras bricht durch den Asphalt, Dächer stürzen ein, Bäume wachsen in deine Häuser. Holz fault schnell, Beton hält länger."],
		["bunker", "Phase 3", "Bunker", Pal.SKY, "Zwei Überlebende bauen in den Ruinen einen Bunker. Beute kommt aus den Gebäuden, die du gebaut hast. Halte ihn 30 Tage am Laufen."],
	]
	for ph in phases:
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 4)
		cell.custom_minimum_size = Vector2(166, 0)
		row.add_child(cell)
		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 6)
		cell.add_child(head)
		var icon := TextureRect.new()
		icon.texture = IconArt.get_icon(ph[0])
		icon.stretch_mode = TextureRect.STRETCH_KEEP
		head.add_child(icon)
		var names := VBoxContainer.new()
		names.add_theme_constant_override("separation", 0)
		head.add_child(names)
		names.add_child(_small(ph[1], Pal.STONE_L))
		names.add_child(_small(ph[2], ph[3]))
		var body := _small(ph[4], Pal.BONE)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(166, 0)
		cell.add_child(body)
	col.add_child(_rule())
	col.add_child(_small("Steuerung", Pal.OCHRE))
	var keys_text := "Klick baut. Ziehen zieht eine Straße oder bewegt die Karte. Rechtsklick legt das Werkzeug weg. Mausrad zoomt. Tasten 1 bis 7 wählen das Werkzeug, X reißt ab, Leertaste hält an, F5 speichert, Esc öffnet das Pausenmenü."
	if Platform.phone:
		keys_text = "Tippe ein Werkzeug an, setze den Finger auf den Platz und ziehe ihn an die richtige Stelle. Loslassen baut. Eine Straße ziehst du mit dem Finger. Zwei Finger bewegen die Karte, Auseinanderziehen zoomt. Das Menü oben rechts pausiert und speichert."
	var keys := _small(keys_text, Pal.BONE)
	keys.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	keys.custom_minimum_size = Vector2(536, 0)
	col.add_child(keys)
	col.add_child(_back_button())
	return shade


# Einstellungen

func _build_settings() -> Control:
	var shade := _shade()
	var panel := _panel(shade, 320)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 7)
	panel.add_child(col)
	col.add_child(_title_label("Einstellungen"))
	var rows := [
		["fullscreen", "Vollbild"],
		["shadows", "Schatten"],
		["particles", "Rauch, Staub und Blätter"],
		["start_speed", "Tempo beim Start"],
	]
	for r in rows:
		if r[0] == "fullscreen" and not Settings.can_fullscreen():
			continue
		var line := HBoxContainer.new()
		col.add_child(line)
		var l := _small(r[1], Pal.BONE)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(l)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(64, 18)
		b.pressed.connect(func():
			Settings.toggle(r[0])
			refresh())
		line.add_child(b)
		_setting_buttons[r[0]] = b
	col.add_child(_rule())
	_wipe_btn = Button.new()
	_wipe_btn.text = "Spielstand löschen"
	_wipe_btn.focus_mode = Control.FOCUS_NONE
	_wipe_btn.add_theme_color_override("font_color", Pal.ROSE)
	_wipe_btn.pressed.connect(_on_wipe)
	col.add_child(_wipe_btn)
	col.add_child(_back_button())
	return shade


func _setting_text(key: String) -> String:
	match key:
		"fullscreen": return "Ein" if Settings.fullscreen else "Aus"
		"shadows": return "Ein" if Settings.shadows else "Aus"
		"particles": return "Ein" if Settings.particles else "Aus"
		"start_speed": return "%d×" % Settings.start_speed
	return ""


## Löschen braucht zwei Klicks, damit es nicht aus Versehen passiert.
func _on_wipe() -> void:
	if not _wipe_armed:
		_wipe_armed = true
		_wipe_btn.text = "Wirklich löschen?"
		return
	GameState.delete_save()
	refresh()


# Sicherheitsabfrage

func _build_confirm() -> Control:
	var shade := _shade()
	var panel := _panel(shade, 260)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	col.add_child(_title_label("Neues Spiel?"))
	var body := _small("Dein gespeicherter Spielstand wird überschrieben.", Pal.BONE)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(236, 0)
	col.add_child(body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)
	var no := Button.new()
	no.text = "Abbrechen"
	no.focus_mode = Control.FOCUS_NONE
	no.custom_minimum_size = Vector2(96, 18)
	no.pressed.connect(show_screen.bind("main"))
	row.add_child(no)
	var yes := Button.new()
	yes.text = "Neu beginnen"
	yes.focus_mode = Control.FOCUS_NONE
	yes.custom_minimum_size = Vector2(110, 18)
	yes.add_theme_color_override("font_color", Pal.YELLOW)
	yes.pressed.connect(_start_new)
	row.add_child(yes)
	return shade


# Bausteine

func _shade() -> ColorRect:
	var shade := ColorRect.new()
	shade.color = Pal.a(Pal.BLACK, 0.62)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.visible = false
	return shade


func _panel(shade: Control, width: int) -> PanelContainer:
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
	panel.custom_minimum_size = Vector2(width, 0)
	center.add_child(panel)
	return panel


func _title_label(text: String) -> Label:
	var t := Label.new()
	t.text = text
	t.add_theme_font_size_override("font_size", PixelFont.SIZE * 2)
	t.add_theme_color_override("font_color", Pal.YELLOW)
	return t


func _small(text: String, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", col)
	return l


func _rule() -> Control:
	var r := ColorRect.new()
	r.color = Pal.STONE_D
	r.custom_minimum_size = Vector2(0, 1)
	return r


func _back_button() -> Button:
	var b := Button.new()
	b.text = "Zurück"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(90, 18)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(show_screen.bind("main"))
	return b


# Ablauf

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and screen != "main":
		show_screen("main")
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if GameState.user_args.has("shot") and _t > float(GameState.user_args.get("wait", "4")):
		get_viewport().get_texture().get_image().save_png(str(GameState.user_args.shot))
		get_tree().quit()


## Ein kleiner Pfeil zeigt auf den Punkt unter der Maus.
func _draw() -> void:
	if _hover == null or _hover.disabled or screen != "main":
		return
	var r := _hover.get_global_rect()
	var bob := roundf(sin(_t * 8.0) * 1.0)
	var p := Vector2(r.position.x - 9 + bob, r.position.y + r.size.y * 0.5 - 4)
	for i in 4:
		draw_rect(Rect2(p + Vector2(i, i), Vector2(1, 7 - i * 2)), Pal.YELLOW)
	draw_rect(Rect2(p + Vector2(0, 0), Vector2(1, 7)), Pal.OCHRE)
