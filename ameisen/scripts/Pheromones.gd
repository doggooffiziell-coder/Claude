extends Node2D
## Duftspuren als 2D-Array: grid[y][x]. Die Werte verblassen alle paar Frames.

const UPDATE_EVERY := 6
const DECAY := 0.993     # pro Update, Spur hält etwa eine halbe Minute
const ROWS := World.G       # Spuren liegen an der Oberfläche und in den Pflanzen

var main
var grid: Array[PackedFloat32Array] = []
var _row_active := PackedByteArray()
var _frame := 0
var _img: Image
var _tex: ImageTexture
var _sprite: Sprite2D


func setup(m) -> void:
	main = m
	_img = Image.create(World.W, ROWS, false, Image.FORMAT_RGBA8)
	_tex = ImageTexture.create_from_image(_img)
	_sprite = Sprite2D.new()
	_sprite.texture = _tex
	_sprite.centered = false
	_sprite.scale = Vector2(World.T, World.T)
	add_child(_sprite)
	clear()


func clear() -> void:
	grid.clear()
	for y in ROWS:
		var row := PackedFloat32Array()
		row.resize(World.W)
		row.fill(0.0)
		grid.append(row)
	_row_active.resize(ROWS)
	_row_active.fill(0)


func deposit(x: int, y: int, amount: float) -> void:
	if y < 0 or y >= ROWS or x < 0 or x >= World.W:
		return
	var row := grid[y]
	# kein Aufsummieren: nahe am Futter bleibt der Duft am stärksten
	row[x] = minf(1.0, maxf(row[x], amount))
	grid[y] = row
	_row_active[y] = 1


func value(x: int, y: int) -> float:
	if y < 0 or y >= ROWS or x < 0 or x >= World.W:
		return 0.0
	return grid[y][x]


## Summe der Duftwerte links und rechts von x auf Reihe y.
func sense(x: int, y: int, reach: int) -> Vector2:
	if y < 0 or y >= ROWS:
		return Vector2.ZERO
	var row := grid[y]
	var l := 0.0
	var r := 0.0
	for k in range(1, reach + 1):
		if x - k >= 0:
			l += row[x - k]
		if x + k < World.W:
			r += row[x + k]
	return Vector2(l, r)


func tick(_dt: float) -> void:
	_frame += 1
	if _frame % UPDATE_EVERY != 0:
		return
	var f := DECAY
	var bytes := PackedByteArray()
	bytes.resize(World.W * ROWS * 4)
	for y in ROWS:
		if _row_active[y] == 0:
			continue
		var row := grid[y]
		var any := false
		for x in World.W:
			var v := row[x]
			if v <= 0.0:
				continue
			v *= f
			if v < 0.02:
				v = 0.0
			else:
				any = true
				var o := (y * World.W + x) * 4
				bytes[o] = 250
				bytes[o + 1] = 235
				bytes[o + 2] = 140
				bytes[o + 3] = int(v * 110.0)
			row[x] = v
		grid[y] = row
		if not any:
			_row_active[y] = 0
	_img.set_data(World.W, ROWS, false, Image.FORMAT_RGBA8, bytes)
	_tex.update(_img)


func to_dict() -> Dictionary:
	var rows: Array = []
	for y in ROWS:
		rows.append(Marshalls.raw_to_base64(grid[y].to_byte_array()))
	return {"rows": rows}


func from_dict(d: Dictionary) -> void:
	clear()
	var rows: Array = d.get("rows", [])
	for y in mini(rows.size(), ROWS):
		var row := Marshalls.base64_to_raw(rows[y]).to_float32_array()
		if row.size() == World.W:
			grid[y] = row
			_row_active[y] = 1
