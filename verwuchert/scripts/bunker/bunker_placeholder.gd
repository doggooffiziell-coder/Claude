extends Control
## Platzhalter für Phase 3. Zeigt, was der Zeitraffer von der Stadt übrig gelassen hat.

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
	title.text = "Phase 3 folgt in Version 0.3.0"
	title.add_theme_font_size_override("font_size", PixelFont.SIZE * 2)
	title.add_theme_color_override("font_color", Pal.YELLOW)
	col.add_child(title)
	var c: Dictionary = GameState.city
	var stages := {}
	var loot := {}
	for b in c.get("buildings", []):
		if b.type == "road" or not b.has("ruin"):
			continue
		stages[b.ruin.stage] = int(stages.get(b.ruin.stage, 0)) + 1
		for item in b.ruin.contents:
			loot[item] = int(loot.get(item, 0)) + int(b.ruin.contents[item])
	var lines: Array[String] = ["Nach %d Jahren liegt die Stadt so da:" % int(c.get("year", 0)), ""]
	for st in ["stehend", "dachlos", "eingestürzt"]:
		if stages.has(st):
			lines.append("%d Gebäude %s" % [stages[st], st])
	lines.append("")
	var lparts: Array[String] = []
	for item in loot:
		lparts.append("%d %s" % [loot[item], BuildingTypes.ITEM_NAMES.get(item, item)])
	lines.append("Fundstücke in den Ruinen: " + (", ".join(lparts) if not lparts.is_empty() else "nichts"))
	lines.append("Neue Bäume: %d   Seed: %d" % [c.get("new_trees", []).size(), int(c.get("seed", 0))])
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
