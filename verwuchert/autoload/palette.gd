class_name Pal
extends RefCounted
## Die 32 Farben von Verwuchert. Jede Grafik im Spiel nutzt nur diese Farben.
## Gedämpft, leicht warm. Licht kommt immer von oben links.

# Dunkel und Stein
const BLACK := Color("141218")
const NIGHT := Color("252334")
const SLATE := Color("3a3b4f")
const STONE_D := Color("565867")
const STONE := Color("7d7f8a")
const STONE_L := Color("a9a9ad")
const BONE := Color("d8d2c0")
const WHITE := Color("efe9da")

# Erde und Holz
const SOIL_D := Color("3b2a26")
const SOIL := Color("5e4235")
const WOOD := Color("85603f")
const WOOD_L := Color("b08a5c")
const SAND := Color("cdb27f")

# Ziegel, Rost, Gelb
const BRICK_D := Color("6e3433")
const BRICK := Color("9a4c3f")
const BRICK_L := Color("c2735a")
const RUST := Color("a35a2f")
const OCHRE := Color("d29a45")
const YELLOW := Color("e8cf7a")

# Pflanzen
const MOSS_D := Color("26372c")
const MOSS := Color("3d5537")
const GRASS := Color("5b7442")
const GRASS_L := Color("84945a")
const LEAF_L := Color("adb276")

# Wasser und Himmel
const TEAL_D := Color("1f3c45")
const TEAL := Color("3b6670")
const WATER := Color("5e8f96")
const SKY := Color("93b7b4")
const BLUE_D := Color("2d3657")
const BLUE := Color("4a5d86")

# Akzente
const PLUM := Color("6b4a63")
const ROSE := Color("b77a7a")

const ALL: Array[Color] = [
	BLACK, NIGHT, SLATE, STONE_D, STONE, STONE_L, BONE, WHITE,
	SOIL_D, SOIL, WOOD, WOOD_L, SAND,
	BRICK_D, BRICK, BRICK_L, RUST, OCHRE, YELLOW,
	MOSS_D, MOSS, GRASS, GRASS_L, LEAF_L,
	TEAL_D, TEAL, WATER, SKY, BLUE_D, BLUE,
	PLUM, ROSE,
]


## Gleiche Farbe mit anderer Deckkraft. Für Schatten und Lichtkegel.
static func a(c: Color, alpha: float) -> Color:
	return Color(c.r, c.g, c.b, alpha)
