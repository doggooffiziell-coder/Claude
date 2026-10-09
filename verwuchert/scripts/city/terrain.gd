class_name Terrain
extends RefCounted
## Gelände aus dem Stadt-Seed. Höhen bestimmen Senken: Dort steht später Wasser.
## Alles ist aus dem Seed berechenbar, darum speichert der Spielstand nur den Seed.

const POND_MIN := 4
const POND_MAX := 7


static func heights(seed_value: int, w: int, h: int) -> PackedFloat32Array:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.09
	noise.fractal_octaves = 3
	var out := PackedFloat32Array()
	out.resize(w * h)
	for y in h:
		for x in w:
			out[y * w + x] = (noise.get_noise_2d(x, y) + 1.0) * 0.5
	return out


## Höhen auch im Rand rund um die Karte, gleiche Formel wie heights(). Größe (w + 2m) mal (h + 2m).
static func heights_margin(seed_value: int, w: int, h: int, m: int) -> PackedFloat32Array:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.09
	noise.fractal_octaves = 3
	var out := PackedFloat32Array()
	out.resize((w + m * 2) * (h + m * 2))
	for y in range(-m, h + m):
		for x in range(-m, w + m):
			out[(y + m) * (w + m * 2) + (x + m)] = (noise.get_noise_2d(x, y) + 1.0) * 0.5
	return out


## Teiche liegen in den tiefsten Senken, nie am Rand.
static func ponds(seed_value: int, w: int, h: int, count: int) -> PackedByteArray:
	var hs := heights(seed_value, w, h)
	var mask := PackedByteArray()
	mask.resize(w * h)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 77
	for n in count:
		var best := -1
		var best_h := 9.0
		for y in range(2, h - 2):
			for x in range(2, w - 2):
				var i := y * w + x
				if mask[i] == 0 and hs[i] < best_h and not _near_mask(mask, w, h, x, y, 3):
					best_h = hs[i]
					best = i
		if best < 0:
			break
		var want := rng.randi_range(POND_MIN, POND_MAX)
		var cells: Array[int] = [best]
		mask[best] = 1
		while cells.size() < want:
			var cand := -1
			var cand_h := 9.0
			for c in cells:
				var cx := c % w
				var cy := c / w
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx: int = cx + d.x
					var ny: int = cy + d.y
					if nx < 2 or ny < 2 or nx >= w - 2 or ny >= h - 2:
						continue
					var ni := ny * w + nx
					if mask[ni] == 0 and hs[ni] < cand_h:
						cand_h = hs[ni]
						cand = ni
			if cand < 0:
				break
			mask[cand] = 1
			cells.append(cand)
	return mask


static func _near_mask(mask: PackedByteArray, w: int, h: int, x: int, y: int, r: int) -> bool:
	for yy in range(maxi(0, y - r), mini(h, y + r + 1)):
		for xx in range(maxi(0, x - r), mini(w, x + r + 1)):
			if mask[yy * w + xx] != 0:
				return true
	return false
