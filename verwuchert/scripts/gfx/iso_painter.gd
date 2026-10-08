class_name IsoPainter
extends RefCounted
## Malt Flächen im isometrischen Raum Pixel für Pixel. Jede Fläche ist ein Parallelogramm
## oder Dreieck aus Ecke o und den Kanten a und b in Kachelkoordinaten (u, v) und Pixelhöhe z.
## Die Füllfunktion bekommt s und t (0 bis 1 entlang a und b) und die Pixelposition.
## Sie gibt eine Farbe zurück oder [Farbe, Leuchtfarbe]. Später Gemaltes liegt vorne.

const EPS := 0.0005

var c: PixelCanvas
var g: PixelCanvas
var origin: Vector2


## Leinwand für ein Gebäude mit w x h Feldern und Platz nach oben.
static func for_footprint(w: int, h: int, top_space: int) -> IsoPainter:
	var p := IsoPainter.new()
	var cw := (w + h) * 32
	var ch := (w + h) * 16 + top_space
	p.c = PixelCanvas.new(cw, ch)
	p.g = PixelCanvas.new(cw, ch)
	p.origin = Vector2(h * 32, top_space)
	return p


func P(u: float, v: float, z: float = 0.0) -> Vector2:
	return origin + Vector2((u - v) * 32.0, (u + v) * 16.0 - z)


func quad(o: Vector3, a: Vector3, b: Vector3, fill: Callable, tri := false) -> void:
	var p0 := P(o.x, o.y, o.z)
	var pa := P(o.x + a.x, o.y + a.y, o.z + a.z) - p0
	var pb := P(o.x + b.x, o.y + b.y, o.z + b.z) - p0
	var det := pa.x * pb.y - pa.y * pb.x
	if absf(det) < 0.0001:
		return
	var xs := [p0.x, p0.x + pa.x, p0.x + pb.x, p0.x + pa.x + pb.x]
	var ys := [p0.y, p0.y + pa.y, p0.y + pb.y, p0.y + pa.y + pb.y]
	var x0 := maxi(0, floori(xs.min()) - 1)
	var x1 := mini(c.w - 1, ceili(xs.max()) + 1)
	var y0 := maxi(0, floori(ys.min()) - 1)
	var y1 := mini(c.h - 1, ceili(ys.max()) + 1)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var dx := x + 0.5 - p0.x
			var dy := y + 0.5 - p0.y
			var s := (dx * pb.y - dy * pb.x) / det
			var t := (pa.x * dy - pa.y * dx) / det
			if s < -EPS or t < -EPS or s > 1.0 + EPS or t > 1.0 + EPS:
				continue
			if tri and s + t > 1.0 + EPS:
				continue
			var r = fill.call(clampf(s, 0.0, 1.0), clampf(t, 0.0, 1.0), x, y)
			if r is Color:
				if r.a > 0.0:
					c.px(x, y, r)
			elif r is Array:
				if r[0].a > 0.0:
					c.px(x, y, r[0])
				if r.size() > 1 and r[1].a > 0.0:
					g.px(x, y, r[1])


## Bodenfläche von (u0, v0) bis (u1, v1) auf Höhe z.
func ground(u0: float, v0: float, u1: float, v1: float, z: float, fill: Callable) -> void:
	quad(Vector3(u0, v0, z), Vector3(u1 - u0, 0, 0), Vector3(0, v1 - v0, 0), fill)


## Linke sichtbare Wand (zeigt nach links unten, liegt im Licht). s läuft nach rechts, t nach oben.
func wall_left(u0: float, u1: float, v: float, z0: float, z1: float, fill: Callable) -> void:
	quad(Vector3(u0, v, z0), Vector3(u1 - u0, 0, 0), Vector3(0, 0, z1 - z0), fill)


## Rechte sichtbare Wand (zeigt nach rechts unten, im Schatten). s läuft nach links, t nach oben.
func wall_right(u: float, v0: float, v1: float, z0: float, z1: float, fill: Callable) -> void:
	quad(Vector3(u, v1, z0), Vector3(0, v0 - v1, 0), Vector3(0, 0, z1 - z0), fill)


## Kiste mit zwei Wänden und Deckel in festen Farben.
func box(u0: float, v0: float, u1: float, v1: float, z0: float, z1: float, left: Color, right: Color, top: Color) -> void:
	wall_left(u0, u1, v1, z0, z1, func(_s, _t, _x, _y): return left)
	wall_right(u1, v0, v1, z0, z1, func(_s, _t, _x, _y): return right)
	ground(u0, v0, u1, v1, z1, func(_s, _t, _x, _y): return top)


## Senkrechter Zylinder. Schattierung von links hell nach rechts dunkel.
func cylinder(cu: float, cv: float, r: float, z0: float, z1: float, ramp: Array, top: Color, open_top := false) -> void:
	var cen := P(cu, cv, 0)
	var rx := r * 45.25
	var ry := r * 22.63
	var x0 := floori(cen.x - rx)
	var x1 := ceili(cen.x + rx)
	for x in range(x0, x1 + 1):
		var nx := (x + 0.5 - cen.x) / rx
		if absf(nx) > 1.0:
			continue
		var dy := sqrt(maxf(0.0, 1.0 - nx * nx)) * ry
		var sh := (nx + 1.0) * 0.5
		var idx := clampi(int(sh * ramp.size()), 0, ramp.size() - 1)
		var col: Color = ramp[idx]
		var ybot := int(round(cen.y + dy - z0))
		var ytop := int(round(cen.y - z1))
		for y in range(ytop, ybot + 1):
			c.px(x, y, col)
	# Deckel
	for y in range(floori(cen.y - z1 - ry), ceili(cen.y - z1 + ry) + 1):
		for x in range(x0, x1 + 1):
			var nx2 := (x + 0.5 - cen.x) / rx
			var ny2 := (y + 0.5 - (cen.y - z1)) / ry
			if nx2 * nx2 + ny2 * ny2 <= 1.0:
				var inner := nx2 * nx2 + ny2 * ny2 <= 0.55
				c.px(x, y, (Pal.NIGHT if inner else top) if open_top else top)


## Linie im Raum.
func line3(a: Vector3, b: Vector3, col: Color) -> void:
	var pa := P(a.x, a.y, a.z)
	var pb := P(b.x, b.y, b.z)
	c.line(int(round(pa.x)), int(round(pa.y)), int(round(pb.x)), int(round(pb.y)), col)
