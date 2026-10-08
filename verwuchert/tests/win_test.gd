extends SceneTree
var n := 0
func _process(_d: float) -> bool:
	n += 1
	if n == 6:
		var w := root
		print("size=", w.size, " scale_size=", w.content_scale_size, " mode=", w.content_scale_mode, " aspect=", w.content_scale_aspect, " stretch=", w.content_scale_stretch, " visible=", root.get_visible_rect().size)
		return true
	return false
