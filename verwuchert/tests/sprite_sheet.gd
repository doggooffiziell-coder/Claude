extends SceneTree
## Zeigt alle Gebäude-Varianten nebeneinander für die Durchsicht.
var frames := 0

func _initialize() -> void:
	var bg := ColorRect.new()
	bg.color = Pal.GRASS
	bg.size = Vector2(640, 360)
	root.add_child(bg)
	var x := 4
	var y := 4
	var row_h := 0
	var list := []
	for v in 5:
		list.append(["house", 300 + v * 13, "ziegel" if v % 2 == 0 else "holz"])
	for v in 3:
		list.append(["shop", 50 + v * 7, "ziegel" if v % 2 == 0 else "beton"])
	list.append(["park", 3, ""])
	list.append(["park", 4, ""])
	list.append(["park", 8, ""])
	list.append(["water_tower", 11, "stahl"])
	list.append(["factory", 21, "ziegel"])
	list.append(["factory", 22, "stahl"])
	list.append(["power_plant", 5, "beton"])
	for item in list:
		var d := BuildingArt.make(item[0], item[1], item[2])
		if x + d.size.x > 636:
			x = 4
			y += row_h + 4
			row_h = 0
		var s := Sprite2D.new()
		s.texture = d.tex
		s.centered = false
		s.position = Vector2(x, y)
		root.add_child(s)
		x += d.size.x + 3
		row_h = maxi(row_h, d.size.y)

func _process(_d: float) -> bool:
	frames += 1
	if frames == 4:
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
		return true
	return false
