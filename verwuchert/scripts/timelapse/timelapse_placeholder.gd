extends Control
## Platzhalter für Phase 2. Zeigt, welche Stadtdaten aus Phase 1 angekommen sind.

func _ready() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Pal.NIGHT
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var col := VBoxContainer.new()
	col.position = Vector2(40, 30)
	col.add_theme_constant_override("separation", 6)
	add_child(col)
	var title := Label.new()
	title.text = "Phase 2 folgt in Version 0.2.0"
	title.add_theme_font_size_override("font_size", PixelFont.SIZE * 2)
	title.add_theme_color_override("font_color", Pal.YELLOW)
	col.add_child(title)
	var c: Dictionary = GameState.city
	var counts := {}
	var mats := {}
	var loot := {}
	for b in c.get("buildings", []):
		counts[b.type] = int(counts.get(b.type, 0)) + 1
		mats[b.material] = int(mats.get(b.material, 0)) + 1
		for item in b.contents:
			loot[item] = int(loot.get(item, 0)) + int(b.contents[item])
	var lines: Array[String] = ["Diese Stadt geht an die Zeitraffer-Phase:", ""]
	for t in BuildingTypes.ORDER:
		if counts.has(t):
			lines.append("%d × %s" % [counts[t], BuildingTypes.display_name(t)])
	lines.append("")
	var mparts: Array[String] = []
	for m in mats:
		mparts.append("%s %d" % [BuildingTypes.MATERIAL_NAMES.get(m, m), mats[m]])
	lines.append("Material: " + ", ".join(mparts))
	var lparts: Array[String] = []
	for item in loot:
		lparts.append("%d %s" % [loot[item], BuildingTypes.ITEM_NAMES.get(item, item)])
	lines.append("Inhalt der Gebäude: " + ", ".join(lparts))
	lines.append("Bäume: %d   Seed: %d   Tag: %d" % [c.get("trees", []).size(), int(c.get("seed", 0)), int(c.get("day", 1))])
	var body := Label.new()
	body.text = "\n".join(lines)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(560, 0)
	col.add_child(body)
	var back := Button.new()
	back.text = "Zum Hauptmenü"
	back.focus_mode = Control.FOCUS_NONE
	back.custom_minimum_size = Vector2(110, 20)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	col.add_child(back)
