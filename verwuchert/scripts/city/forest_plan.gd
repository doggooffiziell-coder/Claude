class_name ForestPlan
extends RefCounted
## Dichter Wald im Rand rund um das Baugebiet. Nur Deko, aus dem Seed berechenbar.


static func make(city: Dictionary, margin: int, entry_row: int) -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = int(city.seed) + 404
	var w: int = city.w
	var h: int = city.h
	for y in range(-margin, h + margin):
		for x in range(-margin, w + margin):
			if x >= 0 and y >= 0 and x < w and y < h:
				continue
			if y == entry_row and x < 0:
				continue
			var dist: int = maxi(maxi(-x, x - w + 1), maxi(-y, y - h + 1))
			var chance := 0.3 + dist * 0.15
			for k in 2:
				if rng.randf() < chance:
					var kind := "pine" if rng.randf() < 0.45 else "oak"
					if rng.randf() < 0.15:
						kind = "bush"
					out.append({"x": x, "y": y, "kind": kind, "seed": rng.randi() % 9999,
						"ox": rng.randi_range(-12, 12), "oy": rng.randi_range(-12, 12)})
	return out
