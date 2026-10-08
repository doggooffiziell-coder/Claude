class_name Iso
extends RefCounted
## Isometrische Projektion 2:1. Eine Kachel ist 64 Pixel breit und 32 Pixel hoch.
## Bodenraum: jede Kachel ist ein Quadrat mit 32 Pixeln Kantenlänge (U, V).
## Bildschirm: x = U - V, y = (U + V) / 2. Höhe z geht nach oben ab.

const T := 32
const HW := 32.0
const HH := 16.0

## Die Matrix für draw_set_transform_matrix: zeichnet Bodenraum als Raute.
const GROUND := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)


## Kachelkoordinaten (auch Bruchteile) und Höhe in Pixeln zu Bildschirm.
static func to_screen(u: float, v: float, z: float = 0.0) -> Vector2:
	return Vector2((u - v) * HW, (u + v) * HH - z)


## Bildschirm zu Kachelkoordinaten auf dem Boden.
static func to_tile(p: Vector2) -> Vector2:
	var a := p.x / HW
	var b := p.y / HH
	return Vector2((a + b) * 0.5, (b - a) * 0.5)


static func tile_at(p: Vector2) -> Vector2i:
	var t := to_tile(p)
	return Vector2i(floori(t.x), floori(t.y))


## Bodenraum in Pixeln (U, V) zu Bildschirm.
static func ground_to_screen(g: Vector2) -> Vector2:
	return GROUND * g


static func screen_to_ground(p: Vector2) -> Vector2:
	return GROUND.affine_inverse() * p


static func center(t: Vector2i) -> Vector2:
	return to_screen(t.x + 0.5, t.y + 0.5)


## Untere Ecke einer Fläche. Dort steht ein Gebäude, dort sortiert die Y-Sortierung.
static func bottom(x: int, y: int, w: int, h: int) -> Vector2:
	return to_screen(x + w, y + h)


static func diamond(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([to_screen(x, y), to_screen(x + w, y), to_screen(x + w, y + h), to_screen(x, y + h)])
