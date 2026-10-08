class_name RoadArt
extends RefCounted
## Straßen mit automatischen Übergängen. Maske: N=1, O=2, S=4, W=8.

const N := 1
const E := 2
const S := 4
const W := 8
const T := 32
const WALK := 5


static func tile(mask: int, variant: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = mask * 131 + variant * 7 + 3
	var c := PixelCanvas.new(T, T)
	# Asphalt mit Körnung
	c.rect(0, 0, T, T, Pal.STONE_D)
	c.speckle(0, 0, T, T, Pal.SLATE, 0.16, rng)
	c.speckle(0, 0, T, T, Pal.STONE, 0.05, rng)
	var links := 0
	for bit in [N, E, S, W]:
		if mask & bit:
			links += 1

	# Fahrbahnmarkierung
	var straight_ns := mask == (N | S) or mask == N or mask == S
	var straight_ew := mask == (E | W) or mask == E or mask == W
	if straight_ns:
		for y in range(0, T, 8):
			c.rect(15, y + 2, 2, 4, Pal.BONE)
	elif straight_ew:
		for x in range(0, T, 8):
			c.rect(x + 2, 15, 4, 2, Pal.BONE)
	elif links == 2:
		# Kurve: Mittellinie biegt ab
		var dirs := []
		for bit in [N, E, S, W]:
			if mask & bit:
				dirs.append(bit)
		for bit in dirs:
			match bit:
				N: c.rect(15, 1, 2, 5, Pal.BONE)
				S: c.rect(15, 26, 2, 5, Pal.BONE)
				E: c.rect(26, 15, 5, 2, Pal.BONE)
				W: c.rect(1, 15, 5, 2, Pal.BONE)
		c.rect(15, 15, 2, 2, Pal.BONE)
	elif links >= 3:
		# Kreuzung: Zebrastreifen an jeder Einfahrt
		for bit in [N, E, S, W]:
			if not (mask & bit):
				continue
			match bit:
				N:
					for x in range(WALK + 1, T - WALK - 1, 3):
						c.rect(x, 1, 2, 4, Pal.BONE)
				S:
					for x in range(WALK + 1, T - WALK - 1, 3):
						c.rect(x, T - 5, 2, 4, Pal.BONE)
				W:
					for y in range(WALK + 1, T - WALK - 1, 3):
						c.rect(1, y, 4, 2, Pal.BONE)
				E:
					for y in range(WALK + 1, T - WALK - 1, 3):
						c.rect(T - 5, y, 4, 2, Pal.BONE)

	# Gehwege an offenen Seiten
	if not (mask & N):
		_walk(c, rng, 0, 0, T, WALK, "n")
	if not (mask & S):
		_walk(c, rng, 0, T - WALK, T, WALK, "s")
	if not (mask & W):
		_walk(c, rng, 0, 0, WALK, T, "w")
	if not (mask & E):
		_walk(c, rng, T - WALK, 0, WALK, T, "e")
	# Innere Ecken: kleine Gehweg-Quadrate
	if (mask & N) and (mask & W):
		_walk(c, rng, 0, 0, WALK, WALK, "c")
	if (mask & N) and (mask & E):
		_walk(c, rng, T - WALK, 0, WALK, WALK, "c")
	if (mask & S) and (mask & W):
		_walk(c, rng, 0, T - WALK, WALK, WALK, "c")
	if (mask & S) and (mask & E):
		_walk(c, rng, T - WALK, T - WALK, WALK, WALK, "c")

	# Risse, Gully, Kanaldeckel
	for i in rng.randi_range(0, 2):
		var x := rng.randi_range(WALK + 1, T - WALK - 4)
		var y := rng.randi_range(WALK + 1, T - WALK - 4)
		c.px(x, y, Pal.SLATE)
		c.px(x + 1, y + 1, Pal.NIGHT)
		c.px(x + 1, y + 2, Pal.SLATE)
	if variant % 3 == 0 and links == 2 and (straight_ns or straight_ew):
		var mx := 9 if straight_ns else 21
		var my := 21 if straight_ns else 9
		c.disc(mx + 0.5, my + 0.5, 2.6, Pal.SLATE)
		c.disc(mx + 0.5, my + 0.5, 1.8, Pal.STONE)
		c.px(mx, my, Pal.STONE_D)
		c.px(mx - 1, my - 1, Pal.STONE_L)
	if not (mask & S) and variant % 2 == 0:
		c.rect(20, T - WALK - 2, 4, 2, Pal.NIGHT)
		c.px(21, T - WALK - 2, Pal.STONE_D)
		c.px(23, T - WALK - 2, Pal.STONE_D)
	return c.texture()


## Gehweg mit Platten und Bordstein zur Fahrbahn hin.
static func _walk(c: PixelCanvas, rng: RandomNumberGenerator, x: int, y: int, ww: int, wh: int, side: String) -> void:
	c.rect(x, y, ww, wh, Pal.STONE_L)
	for yy in range(y, y + wh):
		for xx in range(x, x + ww):
			if (xx % 8 == 7 and side in ["n", "s", "c"]) or (yy % 8 == 7 and side in ["w", "e", "c"]):
				c.px(xx, yy, Pal.STONE)
	c.speckle(x, y, ww, wh, Pal.BONE, 0.07, rng)
	c.speckle(x, y, ww, wh, Pal.STONE, 0.05, rng)
	match side:
		"n":
			c.hline(x, y + wh - 1, ww, Pal.SLATE)
			c.hline(x, y + wh - 2, ww, Pal.STONE)
		"s":
			c.hline(x, y, ww, Pal.BONE)
			c.hline(x, y + 1, ww, Pal.STONE_L)
		"w":
			c.vline(x + ww - 1, y, wh, Pal.SLATE)
		"e":
			c.vline(x, y, wh, Pal.STONE)
		"c":
			pass
