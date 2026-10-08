class_name SpriteFactory
extends RefCounted
## Zwischenspeicher für alle im Code gemalten Sprites. Jedes Bild wird nur einmal gemalt.

static var _buildings := {}
static var _trees := {}
static var _roads := {}
static var _road_imgs := {}


## Nur Häuser zeigen drei verschiedene Türseiten. Läden und Fabriken kennen links und rechts,
## alles andere sieht von jeder Seite gleich aus. So entstehen weniger Bilder.
static func norm_facing(type: String, facing: String) -> String:
	match type:
		"house":
			return facing
		"shop", "factory":
			return "right" if facing == "right" else "left"
	return "left"


static func building(type: String, variant: int, material: String, facing: String = "left") -> Dictionary:
	facing = norm_facing(type, facing)
	var key := "%s_%d_%s_%s" % [type, variant, material, facing]
	if not _buildings.has(key):
		_buildings[key] = BuildingArt.make(type, variant, material, facing)
	return _buildings[key]


static func building_for(b: Dictionary) -> Dictionary:
	return building(b.type, int(b.variant), b.material, str(b.get("facing", "left")))


static func tree(kind: String, seed_value: int) -> Dictionary:
	# Wenige Varianten reichen; der Seed wählt eine davon
	var v := seed_value % 6
	var key := "%s_%d" % [kind, v]
	if not _trees.has(key):
		match kind:
			"pine": _trees[key] = NatureArt.pine(v * 97 + 5)
			"bush": _trees[key] = NatureArt.bush(v * 53 + 2)
			"rock": _trees[key] = NatureArt.rock(v * 31 + 9)
			_: _trees[key] = NatureArt.oak(v * 71 + 3)
	return _trees[key]


static func road(mask: int, variant: int) -> ImageTexture:
	var key := mask * 10 + (variant % 6)
	if not _roads.has(key):
		_roads[key] = RoadArt.tile(mask, variant % 6)
	return _roads[key]


static func road_image(mask: int, variant: int) -> Image:
	var key := mask * 10 + (variant % 6)
	if not _road_imgs.has(key):
		_road_imgs[key] = RoadArt.tile_img(mask, variant % 6)
	return _road_imgs[key]
