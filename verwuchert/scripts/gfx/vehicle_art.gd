class_name VehicleArt
extends RefCounted
## Kleine Autos für vier Richtungen. 0 = Osten, 1 = Süden, 2 = Westen, 3 = Norden.

static var _cache := {}


static func car(dir: int, body: Color) -> ImageTexture:
	var key := "%d_%s" % [dir, body.to_html()]
	if _cache.has(key):
		return _cache[key]
	var c: PixelCanvas
	var lt := Shade.light(body)
	var dk := Shade.dark(body)
	if dir == 0 or dir == 2:
		c = PixelCanvas.new(14, 9)
		# Karosserie
		c.rect(1, 3, 12, 4, body)
		c.hline(1, 3, 12, lt)
		c.hline(1, 6, 12, dk)
		# Kabine mit Scheiben
		c.rect(3, 0, 7, 3, body)
		c.hline(4, 0, 5, lt)
		c.rect(4, 1, 2, 2, Pal.BLUE_D)
		c.rect(7, 1, 2, 2, Pal.BLUE_D)
		c.px(4, 1, Pal.SKY)
		c.px(7, 1, Pal.SKY)
		c.vline(9, 1, 2, Pal.BLUE)
		# Räder
		for wx in [2, 9]:
			c.rect(wx, 6, 3, 2, Pal.BLACK)
			c.px(wx + 1, 6, Pal.STONE)
		# Lichter
		c.px(12, 4, Pal.YELLOW)
		c.px(1, 4, Pal.BRICK_L)
		c.px(6, 4, dk)
		c.outline(Pal.BLACK)
		if dir == 2:
			c.img.flip_x()
	else:
		c = PixelCanvas.new(9, 13)
		c.rect(1, 1, 7, 10, body)
		c.vline(1, 1, 10, lt)
		c.vline(7, 1, 10, dk)
		if dir == 1:
			# Zum Betrachter: Dach oben, Frontscheibe, Haube, Scheinwerfer
			c.rect(2, 2, 5, 3, lt)
			c.rect(2, 5, 5, 2, Pal.BLUE_D)
			c.px(2, 5, Pal.SKY)
			c.hline(2, 8, 5, dk)
			c.px(1, 10, Pal.YELLOW)
			c.px(7, 10, Pal.YELLOW)
			c.hline(2, 10, 5, Pal.STONE_L)
		else:
			# Vom Betrachter weg: Heckscheibe unten, Rücklichter
			c.hline(2, 1, 5, dk)
			c.rect(2, 3, 5, 3, lt)
			c.rect(2, 6, 5, 2, Pal.BLUE_D)
			c.px(2, 6, Pal.BLUE)
			c.px(1, 10, Pal.BRICK_L)
			c.px(7, 10, Pal.BRICK_L)
			c.hline(2, 10, 5, dk)
		for wy in [2, 8]:
			c.rect(0, wy, 1, 3, Pal.BLACK)
			c.rect(8, wy, 1, 3, Pal.BLACK)
		c.outline(Pal.BLACK)
	var tex := c.texture()
	_cache[key] = tex
	return tex


static func car_size(dir: int) -> Vector2i:
	return Vector2i(14, 9) if (dir == 0 or dir == 2) else Vector2i(9, 13)
