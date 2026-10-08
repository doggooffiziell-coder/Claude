extends SceneTree
## Misst die Teile der Ladezeit einer neuen Stadt.
func _t(label: String, f: Callable) -> void:
	var t0 := Time.get_ticks_usec()
	f.call()
	print("%-40s %7.1f ms" % [label, (Time.get_ticks_usec() - t0) / 1000.0])


func _initialize() -> void:
	var gs = root.get_node("GameState")
	_t("GameState.new_game", func(): gs.new_game(7))
	var pond: PackedByteArray
	_t("Terrain.ponds", func(): pond = Terrain.ponds(7, 24, 16, 1))
	_t("NatureArt.ground_image (32x24 Felder)", func(): NatureArt.ground_image(7, 24, 16, 4, pond))
	_t("IsoCliff.underside", func(): IsoCliff.underside(6, 6, 34, 46, 7))
	_t("Straßenbild (6 Varianten x 16 Masken)", func():
		for m in 16:
			for v in 6:
				RoadArt.tile(m, v))
	_t("Baum Eiche", func(): NatureArt.oak(3))
	_t("Baum Kiefer", func(): NatureArt.pine(3))
	_t("Baum Busch", func(): NatureArt.bush(3))
	_t("Stein", func(): NatureArt.rock(3))
	_t("Bäume: 6 Varianten x 4 Arten", func():
		for k in ["oak", "pine", "bush", "rock"]:
			for i in 6:
				SpriteFactory.tree(k, i))
	quit()
