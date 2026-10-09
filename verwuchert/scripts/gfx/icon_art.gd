class_name IconArt
extends RefCounted
## Symbole für Werkzeugleiste und Anzeigen. Werkzeug-Symbole 22x22, kleine Symbole 9x9.

static var _cache := {}


static func get_icon(id: String) -> ImageTexture:
	if _cache.has(id):
		return _cache[id]
	var c: PixelCanvas
	match id:
		"road": c = _road()
		"house": c = _house()
		"apartment": c = _apartment()
		"clinic": c = _clinic()
		"warehouse": c = _warehouse()
		"solar": c = _solar()
		"lock": c = _lock()
		"shop": c = _shop()
		"factory": c = _factory()
		"park": c = _park()
		"water_tower": c = _water_tower()
		"power_plant": c = _power_plant()
		"demolish": c = _demolish()
		"years": c = _years()
		"bunker": c = _bunker()
		_: c = _small(id)
	var tex := c.texture()
	_cache[id] = tex
	return tex


static func _road() -> PixelCanvas:
	var c := PixelCanvas.new(22, 22)
	c.poly(PackedVector2Array([Vector2(7, 2), Vector2(15, 2), Vector2(21, 21), Vector2(1, 21)]), Pal.STONE_D)
	c.line(7, 2, 1, 21, Pal.STONE_L)
	c.line(15, 2, 21, 21, Pal.STONE_L)
	for y in [4, 10, 16]:
		c.rect(10, y, 2, 3, Pal.BONE)
	c.outline(Pal.NIGHT)
	return c


static func _house() -> PixelCanvas:
	var c := PixelCanvas.new(22, 22)
	c.rect(4, 10, 14, 10, Pal.BRICK)
	for y in range(12, 20, 3):
		c.hline(4, y, 14, Pal.BRICK_D)
	c.vline(4, 10, 10, Pal.BRICK_L)
	c.poly(PackedVector2Array([Vector2(1, 11), Vector2(11, 2), Vector2(21, 11)]), Pal.SLATE)
	c.poly(PackedVector2Array([Vector2(1, 11), Vector2(11, 2), Vector2(11, 11)]), Pal.STONE_D)
	c.rect(9, 14, 4, 6, Pal.TEAL_D)
	c.px(12, 17, Pal.YELLOW)
	c.rect(5, 13, 3, 3, Pal.YELLOW)
	c.rect(14, 13, 3, 3, Pal.YELLOW)
	c.rect(15, 3, 2, 5, Pal.BRICK_D)
	c.outline(Pal.NIGHT)
	return c


static func _apartment() -> PixelCanvas:
	var c := PixelCanvas.new(22, 22)
	c.rect(3, 3, 16, 18, Pal.BRICK)
	for y in range(5, 20, 3):
		c.hline(3, y, 16, Pal.BRICK_D)
	c.vline(3, 3, 18, Pal.BRICK_L)
	c.rect(2, 2, 18, 2, Pal.STONE)
	for row in 3:
		for col in 3:
			c.rect(5 + col * 5, 5 + row * 4, 3, 3, Pal.YELLOW if (row + col) % 2 == 0 else Pal.BLUE_D)
	c.rect(9, 17, 4, 4, Pal.TEAL_D)
	c.outline(Pal.NIGHT)
	return c


static func _clinic() -> PixelCanvas:
	var c := PixelCanvas.new(22, 22)
	c.rect(2, 8, 18, 12, Pal.BONE)
	c.hline(2, 8, 18, Pal.WHITE)
	c.rect(1, 6, 20, 2, Pal.STONE_L)
	c.rect(4, 12, 3, 3, Pal.BLUE_D)
	c.rect(15, 12, 3, 3, Pal.BLUE_D)
	c.rect(9, 14, 4, 6, Pal.TEAL_D)
	c.rect(7, 1, 8, 7, Pal.WHITE)
	c.rect(10, 2, 2, 5, Pal.BRICK_L)
	c.rect(8, 4, 6, 2, Pal.BRICK_L)
	c.outline(Pal.NIGHT)
	return c


static func _warehouse() -> PixelCanvas:
	var c := PixelCanvas.new(22, 22)
	c.poly(PackedVector2Array([Vector2(1, 9), Vector2(11, 3), Vector2(21, 9)]), Pal.STONE_D)
	c.rect(2, 9, 18, 11, Pal.STONE_L)
	for x in range(3, 20, 3):
		c.vline(x, 9, 11, Pal.STONE)
	c.rect(4, 12, 6, 8, Pal.TEAL)
	c.rect(12, 12, 6, 8, Pal.TEAL)
	c.hline(4, 12, 6, Pal.YELLOW)
	c.hline(12, 12, 6, Pal.YELLOW)
	c.outline(Pal.NIGHT)
	return c


static func _solar() -> PixelCanvas:
	var c := PixelCanvas.new(22, 22)
	c.poly(PackedVector2Array([Vector2(5, 5), Vector2(21, 5), Vector2(17, 15), Vector2(1, 15)]), Pal.BLUE_D)
	for k in 1:
		c.line(9, 5, 5, 15, Pal.BLUE)
		c.line(13, 5, 9, 15, Pal.BLUE)
		c.line(17, 5, 13, 15, Pal.BLUE)
	c.line(3, 10, 19, 10, Pal.BLUE)
	c.line(5, 5, 21, 5, Pal.STONE_L)
	c.px(7, 7, Pal.SKY)
	c.px(15, 8, Pal.SKY)
	c.vline(8, 15, 5, Pal.STONE_D)
	c.vline(14, 15, 5, Pal.STONE_D)
	c.hline(5, 20, 12, Pal.STONE)
	c.outline(Pal.NIGHT)
	return c


## Kleines Schloss für Gebäude, die noch gesperrt sind.
static func _lock() -> PixelCanvas:
	var c := PixelCanvas.new(9, 9)
	c.rect(1, 4, 7, 5, Pal.OCHRE)
	c.hline(1, 4, 7, Pal.YELLOW)
	c.rect(2, 1, 1, 3, Pal.STONE_L)
	c.rect(6, 1, 1, 3, Pal.STONE_L)
	c.hline(2, 0, 5, Pal.STONE_L)
	c.px(4, 6, Pal.NIGHT)
	c.px(4, 7, Pal.NIGHT)
	return c


static func _shop() -> PixelCanvas:
	var c := PixelCanvas.new(22, 22)
	c.rect(2, 6, 18, 14, Pal.STONE_L)
	c.rect(2, 3, 18, 3, Pal.STONE)
	for x in range(1, 21):
		c.vline(x, 7, 3, Pal.ROSE if (x / 2) % 2 == 0 else Pal.BONE)
	c.rect(4, 12, 8, 7, Pal.BLUE_D)
	c.px(5, 13, Pal.SKY)
	c.hline(4, 15, 8, Pal.WOOD)
	c.px(6, 14, Pal.OCHRE)
	c.px(9, 14, Pal.BRICK_L)
	c.rect(14, 12, 4, 8, Pal.TEAL_D)
	c.outline(Pal.NIGHT)
	return c


static func _factory() -> PixelCanvas:
	var c := PixelCanvas.new(22, 22)
	c.rect(16, 1, 3, 12, Pal.BRICK)
	c.vline(16, 1, 12, Pal.BRICK_L)
	c.rect(1, 11, 20, 10, Pal.STONE)
	for k in 3:
		c.poly(PackedVector2Array([Vector2(1 + k * 6, 11), Vector2(7 + k * 6, 6), Vector2(7 + k * 6, 11)]), Pal.STONE_L)
		c.vline(7 + k * 6, 6, 5, Pal.BLUE)
	c.rect(8, 15, 6, 6, Pal.STONE_D)
	c.hline(8, 17, 6, Pal.STONE)
	c.hline(8, 19, 6, Pal.STONE)
	c.rect(3, 14, 3, 3, Pal.YELLOW)
	c.rect(16, 14, 3, 3, Pal.YELLOW)
	c.outline(Pal.NIGHT)
	c.disc(18, 0.5, 1.5, Pal.STONE_L)
	return c


static func _park() -> PixelCanvas:
	var c := PixelCanvas.new(22, 22)
	c.ellipse(11, 18, 10, 3.5, Pal.GRASS_L)
	c.rect(10, 11, 3, 8, Pal.WOOD)
	c.vline(12, 11, 8, Pal.SOIL)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	NatureArt.crown(c, rng, Vector2(11.5, 7.5), 7.0, 6.0)
	c.outline(Pal.MOSS_D)
	c.px(4, 18, Pal.ROSE)
	c.px(17, 19, Pal.YELLOW)
	return c


static func _water_tower() -> PixelCanvas:
	var c := PixelCanvas.new(22, 22)
	# Schaft aus Ziegeln mit Bogenfenstern
	c.rect(7, 10, 8, 11, Pal.BRICK)
	c.vline(7, 10, 11, Pal.BRICK_L)
	c.vline(14, 10, 11, Pal.BRICK_D)
	for y in range(12, 21, 3):
		c.hline(7, y, 8, Pal.BRICK_D)
	for wy in [12, 16]:
		c.rect(10, wy, 2, 3, Pal.BLUE_D)
		c.px(10, wy, Pal.SKY)
	c.rect(10, 18, 2, 3, Pal.WOOD)
	c.rect(6, 20, 10, 2, Pal.STONE_L)
	# Behälter
	c.rect(5, 5, 12, 6, Pal.TEAL)
	c.vline(5, 5, 6, Pal.WATER)
	c.vline(6, 5, 6, Pal.WATER)
	c.vline(16, 5, 6, Pal.TEAL_D)
	c.hline(5, 8, 12, Pal.TEAL_D)
	c.px(10, 6, Pal.WHITE)
	c.px(11, 6, Pal.WHITE)
	c.rect(4, 10, 14, 1, Pal.STONE_L)
	# Kupferdach
	c.poly(PackedVector2Array([Vector2(3, 5), Vector2(11, 0), Vector2(19, 5)]), Pal.MOSS)
	c.poly(PackedVector2Array([Vector2(3, 5), Vector2(11, 0), Vector2(11, 5)]), Pal.GRASS)
	c.outline(Pal.NIGHT)
	return c


## Zeitraffer: Sanduhr mit fallendem Sand.
static func _years() -> PixelCanvas:
	var c := PixelCanvas.new(22, 22)
	c.rect(4, 2, 14, 2, Pal.WOOD_L)
	c.rect(4, 18, 14, 2, Pal.WOOD_L)
	c.hline(4, 2, 14, Pal.SAND)
	c.poly(PackedVector2Array([Vector2(6, 4), Vector2(16, 4), Vector2(11.5, 10.5)]), Pal.SKY)
	c.poly(PackedVector2Array([Vector2(6, 4), Vector2(16, 4), Vector2(11.5, 10.5)]), Pal.a(Pal.WHITE, 0.0))
	c.poly(PackedVector2Array([Vector2(8, 6), Vector2(14, 6), Vector2(11, 9.5)]), Pal.OCHRE)
	c.poly(PackedVector2Array([Vector2(11.5, 10.5), Vector2(6, 18), Vector2(17, 18)]), Pal.SKY)
	c.poly(PackedVector2Array([Vector2(11, 13), Vector2(8, 18), Vector2(15, 18)]), Pal.YELLOW)
	c.vline(11, 10, 4, Pal.OCHRE)
	c.px(7, 5, Pal.WHITE)
	c.px(7, 17, Pal.WHITE)
	c.outline(Pal.NIGHT)
	# Blätter wachsen um das Glas
	c.px(3, 12, Pal.GRASS_L)
	c.px(3, 13, Pal.GRASS)
	c.px(2, 14, Pal.GRASS_L)
	c.px(18, 8, Pal.GRASS_L)
	c.px(19, 9, Pal.GRASS)
	return c


## Bunker: Erdblock mit Stahlluke und Leiter.
static func _bunker() -> PixelCanvas:
	var c := PixelCanvas.new(22, 22)
	c.rect(1, 9, 20, 11, Pal.SOIL)
	c.hline(1, 9, 20, Pal.GRASS)
	c.hline(1, 10, 20, Pal.MOSS)
	for i in 14:
		c.px(2 + (i * 7) % 18, 12 + (i * 5) % 7, Pal.SOIL_D if i % 2 == 0 else Pal.WOOD)
	c.rect(1, 18, 20, 2, Pal.STONE_D)
	c.rect(5, 12, 12, 7, Pal.NIGHT)
	c.frame(5, 12, 12, 7, Pal.STONE_L)
	c.rect(7, 14, 8, 4, Pal.SLATE)
	c.hline(7, 14, 8, Pal.STONE)
	c.px(9, 16, Pal.YELLOW)
	c.px(13, 16, Pal.BRICK_L)
	c.vline(10, 4, 8, Pal.STONE_L)
	c.vline(12, 4, 8, Pal.STONE_L)
	for y in range(5, 12, 2):
		c.px(11, y, Pal.STONE)
	c.rect(8, 2, 6, 3, Pal.STONE_D)
	c.hline(8, 2, 6, Pal.STONE)
	c.outline(Pal.NIGHT)
	return c


static func _power_plant() -> PixelCanvas:
	var c := PixelCanvas.new(22, 22)
	for y in range(3, 21):
		var t := float(20 - y) / 17.0
		var u := (t - 0.7) / 0.7
		var r := 5.0 + 3.0 * u * u
		c.hline(int(8 - r), y, int(r * 2) + 1, Pal.STONE_L)
		c.px(int(8 + r), y, Pal.STONE)
	c.ellipse(8, 3, 6, 1.5, Pal.NIGHT)
	c.rect(13, 12, 8, 9, Pal.STONE)
	c.hline(13, 15, 8, Pal.TEAL)
	c.outline(Pal.NIGHT)
	# Blitz
	c.line(18, 1, 15, 6, Pal.YELLOW)
	c.line(15, 6, 19, 6, Pal.YELLOW)
	c.line(19, 6, 16, 11, Pal.YELLOW)
	return c


static func _demolish() -> PixelCanvas:
	var c := PixelCanvas.new(22, 22)
	# Abrissbirne am Seil
	c.line(3, 2, 14, 2, Pal.OCHRE)
	c.vline(3, 2, 18, Pal.OCHRE)
	c.vline(4, 2, 18, Pal.RUST)
	c.line(14, 2, 14, 9, Pal.STONE_L)
	c.disc(14, 13, 4.5, Pal.STONE_D)
	c.disc(13, 12, 2.5, Pal.STONE)
	c.px(12, 11, Pal.STONE_L)
	c.outline(Pal.NIGHT)
	c.rect(1, 20, 6, 2, Pal.STONE_D)
	return c


## Kleine Symbole 9x9 für die Anzeigen.
static func _small(id: String) -> PixelCanvas:
	var c := PixelCanvas.new(9, 9)
	match id:
		"coin":
			c.disc(4.5, 4.5, 4, Pal.OCHRE)
			c.disc(4, 4, 3, Pal.YELLOW)
			c.vline(4, 2, 5, Pal.OCHRE)
			c.px(3, 2, Pal.WHITE)
		"people":
			c.disc(3, 2, 1.6, Pal.SAND)
			c.rect(1, 4, 4, 4, Pal.TEAL)
			c.disc(6.5, 3, 1.5, Pal.ROSE)
			c.rect(5, 5, 3, 3, Pal.OCHRE)
		"crew":
			c.rect(1, 1, 6, 2, Pal.OCHRE)
			c.hline(0, 3, 8, Pal.YELLOW)
			c.line(2, 8, 7, 4, Pal.WOOD_L)
			c.rect(6, 3, 3, 2, Pal.STONE_L)
		"clock":
			c.disc(4.5, 4.5, 4, Pal.BONE)
			c.vline(4, 2, 3, Pal.NIGHT)
			c.hline(4, 4, 3, Pal.NIGHT)
		"sun":
			c.disc(4.5, 4.5, 2.5, Pal.YELLOW)
			for p in [Vector2i(4, 0), Vector2i(4, 8), Vector2i(0, 4), Vector2i(8, 4), Vector2i(1, 1), Vector2i(7, 1), Vector2i(1, 7), Vector2i(7, 7)]:
				c.px(p.x, p.y, Pal.OCHRE)
		"moon":
			c.disc(4.5, 4.5, 3.5, Pal.BONE)
			c.disc(6, 3.5, 3, Color(0, 0, 0, 0))
			for y in 9:
				for x in 9:
					if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(6.2, 3.4)) < 3.0:
						c.img.set_pixel(x, y, Color(0, 0, 0, 0))
		"bolt":
			c.line(5, 0, 2, 4, Pal.YELLOW)
			c.line(2, 4, 6, 4, Pal.YELLOW)
			c.line(6, 4, 3, 8, Pal.YELLOW)
			c.px(4, 1, Pal.WHITE)
		"drop":
			c.px(4, 0, Pal.SKY)
			c.hline(3, 1, 3, Pal.SKY)
			c.disc(4.5, 5, 3, Pal.WATER)
			c.px(3, 4, Pal.WHITE)
		"road_need":
			c.rect(0, 2, 9, 5, Pal.STONE_D)
			c.hline(1, 4, 2, Pal.BONE)
			c.hline(6, 4, 2, Pal.BONE)
		"people_need":
			c.disc(4.5, 2, 1.8, Pal.SAND)
			c.rect(2, 4, 5, 4, Pal.ROSE)
		"hourglass":
			c.hline(1, 0, 7, Pal.WOOD_L)
			c.hline(1, 8, 7, Pal.WOOD_L)
			c.poly(PackedVector2Array([Vector2(2, 1), Vector2(7, 1), Vector2(4.5, 4.5)]), Pal.SAND)
			c.poly(PackedVector2Array([Vector2(4.5, 4.5), Vector2(2, 8), Vector2(7, 8)]), Pal.OCHRE)
		"save":
			c.rect(0, 0, 9, 9, Pal.BLUE)
			c.rect(2, 0, 5, 3, Pal.STONE_L)
			c.rect(1, 5, 7, 4, Pal.BONE)
			c.px(5, 1, Pal.BLUE_D)
		"pause":
			c.rect(1, 1, 3, 7, Pal.BONE)
			c.rect(5, 1, 3, 7, Pal.BONE)
		"play1", "play2", "play3":
			var n := int(id.substr(4))
			for k in n:
				var x0 := k * 3 + (3 - n) * 1
				c.poly(PackedVector2Array([Vector2(x0, 1), Vector2(x0 + 4, 4.5), Vector2(x0, 8)]), Pal.BONE)
		"leaf":
			c.ellipse(4.5, 4.5, 3.5, 2.5, Pal.GRASS_L)
			c.line(1, 7, 7, 2, Pal.MOSS)
		"warn":
			c.poly(PackedVector2Array([Vector2(4.5, 0), Vector2(9, 8.5), Vector2(0, 8.5)]), Pal.YELLOW)
			c.vline(4, 3, 3, Pal.NIGHT)
			c.px(4, 7, Pal.NIGHT)
		"info":
			c.disc(4.5, 4.5, 4, Pal.BLUE)
			c.px(4, 2, Pal.WHITE)
			c.vline(4, 4, 3, Pal.WHITE)
		"close":
			c.line(1, 1, 7, 7, Pal.BONE)
			c.line(7, 1, 1, 7, Pal.BONE)
		"menu":
			c.rect(1, 1, 7, 1, Pal.BONE)
			c.rect(1, 4, 7, 1, Pal.BONE)
			c.rect(1, 7, 7, 1, Pal.BONE)
		"zoom":
			c.disc(3.5, 3.5, 3.0, Pal.BONE)
			c.disc(3.5, 3.5, 1.8, Pal.NIGHT)
			c.line(6, 6, 8, 8, Pal.BONE)
			c.px(2, 2, Pal.SKY)
	return c
