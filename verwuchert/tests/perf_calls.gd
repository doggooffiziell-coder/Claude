extends SceneTree
## Misst einzelne teure Aufrufe der Stadt.
var step := 0
var scene


func _initialize() -> void:
	Engine.max_fps = 0
	change_scene_to_file("res://scenes/phase1_city.tscn")


func _t(label: String, n: int, f: Callable) -> void:
	var t0 := Time.get_ticks_usec()
	for i in n:
		f.call()
	print("%-34s %.3f ms pro Aufruf" % [label, (Time.get_ticks_usec() - t0) / 1000.0 / n])


func _process(_d: float) -> bool:
	step += 1
	if scene == null:
		if current_scene != null and current_scene.has_method("map_screen_rect") and current_scene.loaded:
			scene = current_scene
			step = 0
		return false
	if step < 20:
		return false
	var b = scene
	print("Gebäude: %d, Bäume im Spiel: %d, Masten: %d" % [b.building_views.size(), b.tree_views.size(), b.pole_views.size()])
	_t("_update_status", 20, func(): b._update_status())
	_t("_rebuild_poles", 10, func(): b._rebuild_poles())
	_t("CityBuilder._process(0.016)", 30, func(): b._process(0.016))
	_t("Shadows queue+draw (hulls)", 1, func(): pass)
	var hud = b.get_node("HUD/Root")
	_t("HUD._process(0.016)", 30, func(): hud._process(0.016))
	_t("HUD._update_info", 30, func(): hud._update_info())
	var v = b.building_views.values()[0]
	_t("BuildingView.hit (Bildabruf)", 10, func(): v.hit(Vector2(0, 0)))
	_t("_pick_building (alle Gebäude)", 5, func(): b._pick_building())
	_t("Sprite: Haus neue Variante", 10, func(): BuildingArt.house(randi() % 100000, "ziegel", "left"))
	_t("Sprite: Laden neue Variante", 10, func(): BuildingArt.shop(randi() % 100000, "ziegel", "left"))
	_t("Sprite: Fabrik neue Variante", 5, func(): BuildingArt.factory(randi() % 100000, "ziegel", "left"))
	_t("Sprite: Kraftwerk", 3, func(): BuildingArt.power_plant(randi() % 100000, "beton", "left"))
	_t("Sprite: Wasserturm", 5, func(): BuildingArt.water_tower(randi() % 100000, "stahl", "left"))
	_t("Sprite: Park", 10, func(): BuildingArt.park(randi() % 100000, "", "left"))
	_t("UiTheme.button_box", 20, func(): UiTheme.button_box("normal"))
	return true
