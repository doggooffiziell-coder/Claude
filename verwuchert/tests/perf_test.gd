extends SceneTree
## Misst die Rechenzeit pro Bild in der Stadt ohne Fenster. Schaltet Gruppen nacheinander ab,
## so sieht man, was wie viel kostet. Start: godot --headless -s res://tests/perf_test.gd -- --demo --seed=7

const GROUPS := [
	["HUD", "HUD"], ["Bäume und Gebäude", "World/Objects"], ["Boden", "World/Ground"], ["Schatten", "World/Shadows"],
	["Lichtkegel", "World/LightPools"], ["Leitungen", "World/Wires"], ["Partikel", "World/Particles"],
	["Overlay", "World/TopOverlay"], ["Himmel", "World/Sky"], ["Verkehr", "Traffic"],
]

var step := 0
var scene
var load_t0 := 0
var sample_frames := 0
var sample_t0 := 0
var group_index := -1
var base_ms := 0.0
var draws := 0


func _initialize() -> void:
	Engine.max_fps = 0
	load_t0 = Time.get_ticks_usec()
	change_scene_to_file("res://scenes/phase1_city.tscn")


func _process(_d: float) -> bool:
	step += 1
	if scene == null:
		if current_scene != null and current_scene.has_method("map_screen_rect") and current_scene.loaded:
			scene = current_scene
			print("Ladezeit der Stadt: %.0f ms" % ((Time.get_ticks_usec() - load_t0) / 1000.0))
			step = 0
		return false
	if step < 40:
		return false
	if sample_frames == 0:
		sample_t0 = Time.get_ticks_usec()
	sample_frames += 1
	if sample_frames < 200:
		return false
	var ms := (Time.get_ticks_usec() - sample_t0) / 1000.0 / sample_frames
	if group_index < 0:
		base_ms = ms
		print("Alles an: %.2f ms pro Bild (%.0f Bilder pro Sekunde)" % [ms, 1000.0 / ms])
	else:
		var g: Array = GROUPS[group_index]
		print("  ohne %-20s %.2f ms  (spart %.2f ms)" % [g[0], ms, base_ms - ms])
		base_ms = ms
	group_index += 1
	sample_frames = 0
	if group_index >= GROUPS.size():
		print("Rest ohne alles: %.2f ms" % base_ms)
		return true
	var node: Node = scene.get_node_or_null(GROUPS[group_index][1])
	if node:
		node.process_mode = Node.PROCESS_MODE_DISABLED
	return false
