class_name GroundJob
extends RefCounted
## Malt den Boden in Häppchen. step() arbeitet nur so lange, wie das Zeitbudget erlaubt,
## so bleibt das Spiel beim Laden bedienbar und zeigt einen Fortschrittsbalken.
## Das Gras entsteht aus einem weichen Feld, das pro Vierer-Zelle gelesen und pro Pixel
## mit einem geordneten Raster entschieden wird. Eine Nachschlagetabelle ersetzt die Farbkette.

const T := 32
const CELL := 4
const LEVELS := 1024
## Größter Wert vor dem Raster plus Rasterhöhe, damit der Index nie überläuft.
const MAX_V := 1.07

var image: Image
var progress := 0.0
var done := false

var _seed: int
var _w: int
var _h: int
var _margin: int
var _pond: PackedByteArray
var _gw: int
var _gh: int
var _cols: int
var _rows: int
var _noise: FastNoiseLite
var _fine: FastNoiseLite
var _rng := RandomNumberGenerator.new()
var _grid := PackedFloat32Array()
var _pix := PackedInt32Array()
var _lut := PackedInt32Array()
var _band := PackedByteArray()
var _bay := PackedFloat32Array()
var _phase := 0
var _row := 0
var _tuft_i := 0
var _tuft_n := 0
var _pond_tiles: Array[Vector2i] = []
var _pond_i := 0


func _init(seed_value: int, w: int, h: int, margin: int, pond: PackedByteArray) -> void:
	_seed = seed_value
	_w = w
	_h = h
	_margin = margin
	_pond = pond
	_gw = (w + margin * 2) * T
	_gh = (h + margin * 2) * T
	_cols = _gw / CELL + 2
	_rows = _gh / CELL + 2
	_noise = FastNoiseLite.new()
	_noise.seed = seed_value
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.09 / T
	_noise.fractal_octaves = 3
	_fine = FastNoiseLite.new()
	_fine.seed = seed_value + 5
	_fine.frequency = 0.08
	_rng.seed = seed_value + 11
	_grid.resize(_cols * _rows)
	_pix.resize(_gw * _gh)
	_make_tables()
	for ty in h:
		for tx in w:
			if pond[ty * w + tx] != 0:
				_pond_tiles.append(Vector2i(tx, ty))
	_tuft_n = _gw * _gh / 70


## Alles auf einmal, für Menü und Tests.
static func run_all(seed_value: int, w: int, h: int, margin: int, pond: PackedByteArray) -> Image:
	var job := GroundJob.new(seed_value, w, h, margin, pond)
	while not job.step(100000.0):
		pass
	return job.image


static func _to_int(c: Color) -> int:
	return int(c.r8) | (int(c.g8) << 8) | (int(c.b8) << 16) | (255 << 24)


## Farbe nach Stufe v und Schachbrett-Seite. Die Stufen sind dieselben wie im ersten Entwurf.
func _class_color(v: float, par: int) -> Color:
	if v < 0.16:
		return Pal.MOSS_D if par == 0 else Pal.MOSS
	if v < 0.33:
		return Pal.MOSS
	if v < 0.4:
		return Pal.MOSS if par == 0 else Pal.GRASS
	if v < 0.66:
		return Pal.GRASS
	if v < 0.72:
		return Pal.GRASS_L if par == 0 else Pal.GRASS
	if v < 0.82:
		return Pal.GRASS_L
	return Pal.GRASS_L if par == 0 else Pal.LEAF_L


func _band_of(v: float) -> int:
	if v < 0.16: return 0
	if v < 0.33: return 1
	if v < 0.4: return 2
	if v < 0.66: return 3
	if v < 0.72: return 4
	if v < 0.82: return 5
	return 6


func _make_tables() -> void:
	var size := int(MAX_V * LEVELS) + 2
	_lut.resize(size * 2)
	_band.resize(size)
	for i in size:
		var v := (float(i) + 0.5) / LEVELS
		_band[i] = _band_of(v)
		for par in 2:
			_lut[i * 2 + par] = _to_int(_class_color(v, par))
	_bay.resize(16)
	for i in 16:
		_bay[i] = float(PixelCanvas.BAYER[i]) / 16.0 * 0.08


## Gibt true zurück, wenn alles fertig ist. budget_ms begrenzt die Arbeit dieses Aufrufs.
func step(budget_ms: float) -> bool:
	if done:
		return true
	var t0 := Time.get_ticks_usec()
	var limit := int(budget_ms * 1000.0)
	while Time.get_ticks_usec() - t0 < limit:
		match _phase:
			0:
				_grid_row(_row)
				_row += 1
				progress = 0.05 * float(_row) / _rows
				if _row >= _rows:
					_phase = 1
					_row = 0
			1:
				_pixel_cells(_row)
				_row += 1
				progress = 0.05 + 0.75 * float(_row) / (_gh / CELL)
				if _row >= _gh / CELL:
					image = Image.create_from_data(_gw, _gh, false, Image.FORMAT_RGBA8, _pix.to_byte_array())
					_phase = 2
			2:
				_tufts(200)
				progress = 0.8 + 0.12 * float(_tuft_i) / _tuft_n
				if _tuft_i >= _tuft_n:
					_phase = 3
			3:
				if _pond_i >= _pond_tiles.size():
					_phase = 4
				else:
					var t := _pond_tiles[_pond_i]
					NatureArt._pond_tile(image, _pond, _w, _h, t.x, t.y, _margin * T, _margin * T, _rng)
					_pond_i += 1
					progress = 0.92 + 0.08 * float(_pond_i) / maxi(1, _pond_tiles.size())
			_:
				done = true
				progress = 1.0
				return true
	return false


## Eine Zeile des weichen Feldes. Senken sind dunkler, Kuppen heller, außen ist es dunkler.
func _grid_row(gy: int) -> void:
	var ox := _margin * T
	var oy := _margin * T
	var wy := gy * CELL - oy
	var dy := maxf(0.0, maxf(-wy, wy - _h * T))
	for gx in _cols:
		var wx := gx * CELL - ox
		var v := (_noise.get_noise_2d(wx, wy) + 1.0) * 0.5
		v += _fine.get_noise_2d(wx, wy) * 0.08
		var dx := maxf(0.0, maxf(-wx, wx - _w * T))
		v -= clampf((dx + dy) / 40.0, 0.0, 1.0) * 0.35
		_grid[gy * _cols + gx] = clampf(v, 0.0, 0.99)


## Eine Zeile aus Vierer-Zellen, also vier Pixelzeilen. Ebene Zellen werden ohne Rechnung gefüllt.
func _pixel_cells(cy: int) -> void:
	var base := cy * _cols
	var cells := _gw / CELL
	for cx in cells:
		var a := _grid[base + cx]
		var b := _grid[base + cx + 1]
		var c := _grid[base + _cols + cx]
		var d := _grid[base + _cols + cx + 1]
		var lo := minf(minf(a, b), minf(c, d))
		var hi := maxf(maxf(a, b), maxf(c, d)) + 0.08
		var i0 := int(lo * LEVELS)
		var i1 := int(hi * LEVELS)
		var x0 := cx * CELL
		var y0 := cy * CELL
		var band := _band[i0]
		# Ebene Zellen in den Stufen ohne Muster: Moos, Gras, helles Gras
		if band == _band[i1] and (band == 1 or band == 3 or band == 5):
			var col := _lut[i0 * 2]
			for py in CELL:
				var o := (y0 + py) * _gw + x0
				_pix[o] = col
				_pix[o + 1] = col
				_pix[o + 2] = col
				_pix[o + 3] = col
			continue
		for py in CELL:
			var fy := float(py) * 0.25
			var left := a + (c - a) * fy
			var right := b + (d - b) * fy
			var dv := (right - left) * 0.25
			var v := left
			var o := (y0 + py) * _gw + x0
			var bi := ((y0 + py) & 3) * 4
			var par := (x0 + y0 + py) & 1
			for px in CELL:
				var idx := int((v + _bay[bi + px]) * LEVELS)
				_pix[o + px] = _lut[(idx << 1) | ((par + px) & 1)]
				v += dv


## Grashalme, Blumen und Kiesel, n Stück pro Aufruf.
func _tufts(n: int) -> void:
	var img := image
	var stop := mini(_tuft_i + n, _tuft_n)
	while _tuft_i < stop:
		_tuft_i += 1
		var x := _rng.randi_range(1, _gw - 4)
		var y := _rng.randi_range(2, _gh - 4)
		var base := img.get_pixel(x, y)
		var lt := Shade.light(base)
		var dk := Shade.dark(base)
		match _rng.randi() % 6:
			0, 1, 2:
				img.set_pixel(x, y, dk)
				img.set_pixel(x, y - 1, lt)
				if _rng.randf() < 0.5:
					img.set_pixel(x + 1, y - 2, lt)
				if _rng.randf() < 0.5:
					img.set_pixel(x - 1, y - 1, lt)
			3:
				img.set_pixel(x, y, dk)
				img.set_pixel(x + 1, y, dk)
			4:
				if _rng.randf() < 0.45:
					var fc: Color = [Pal.YELLOW, Pal.WHITE, Pal.ROSE, Pal.SKY, Pal.BONE][_rng.randi() % 5]
					img.set_pixel(x, y, fc)
					img.set_pixel(x, y + 1, Pal.MOSS)
					if _rng.randf() < 0.6:
						img.set_pixel(x + 2, y + 1, fc)
						img.set_pixel(x + 2, y + 2, Pal.MOSS)
			_:
				if _rng.randf() < 0.3:
					img.set_pixel(x, y, Pal.STONE)
					img.set_pixel(x + 1, y, Pal.STONE_D)
					img.set_pixel(x, y - 1, Pal.STONE_L)
