class_name Shade
extends RefCounted
## Farbrampen der Palette. step() geht eine Stufe heller oder dunkler, ohne die Palette zu verlassen.

static var _ramps: Array = []


static func _init_ramps() -> void:
	_ramps = [
		[Pal.BLACK, Pal.NIGHT, Pal.SLATE, Pal.STONE_D, Pal.STONE, Pal.STONE_L, Pal.BONE, Pal.WHITE],
		[Pal.SOIL_D, Pal.SOIL, Pal.WOOD, Pal.WOOD_L, Pal.SAND, Pal.BONE],
		[Pal.SOIL_D, Pal.BRICK_D, Pal.BRICK, Pal.BRICK_L, Pal.SAND],
		[Pal.SOIL_D, Pal.SOIL, Pal.RUST, Pal.OCHRE, Pal.YELLOW],
		[Pal.MOSS_D, Pal.MOSS, Pal.GRASS, Pal.GRASS_L, Pal.LEAF_L],
		[Pal.NIGHT, Pal.TEAL_D, Pal.TEAL, Pal.WATER, Pal.SKY, Pal.WHITE],
		[Pal.NIGHT, Pal.BLUE_D, Pal.BLUE, Pal.WATER, Pal.SKY],
		[Pal.NIGHT, Pal.PLUM, Pal.ROSE, Pal.BRICK_L, Pal.SAND],
	]


static func step(c: Color, n: int) -> Color:
	if _ramps.is_empty():
		_init_ramps()
	for ramp in _ramps:
		for i in ramp.size():
			if ramp[i].is_equal_approx(c):
				return ramp[clampi(i + n, 0, ramp.size() - 1)]
	return c.darkened(0.2) if n < 0 else c.lightened(0.2)


static func light(c: Color) -> Color:
	return step(c, 1)


static func dark(c: Color) -> Color:
	return step(c, -1)
