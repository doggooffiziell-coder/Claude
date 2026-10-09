class_name RuinView
extends BuildingView
## Ein Gebäude im Zeitraffer. Der Shader lässt es altern, ab dem Einsturz liegt Schutt am Fuß.

const RUBBLE := {
	"ziegel": [Pal.BRICK, Pal.BRICK_D, Pal.BRICK_L, Pal.STONE],
	"holz": [Pal.WOOD, Pal.WOOD_L, Pal.SOIL, Pal.SOIL_D],
	"beton": [Pal.STONE, Pal.STONE_L, Pal.STONE_D, Pal.SLATE],
	"stahl": [Pal.STONE_D, Pal.RUST, Pal.SLATE, Pal.OCHRE],
	"pflanzen": [Pal.SOIL, Pal.WOOD, Pal.MOSS, Pal.GRASS],
}

var rec: Dictionary
var model: DecayModel
var mat: ShaderMaterial
var f := {}
var _last := {}
var _rubble: Array = []
var _rubble_q := -1.0


func attach(decay: DecayModel, r: Dictionary) -> void:
	model = decay
	rec = r
	use_parent_material = false
	mat = ShaderMaterial.new()
	mat.shader = preload("res://shaders/ruin.gdshader")
	material = mat
	mat.set_shader_parameter("seed", float(rec.seed))
	_make_rubble()
	apply(0.0, Color.WHITE, 0.0)


func _make_rubble() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([int(rec.seed * 10.0), "rubble"])
	var fp := footprint_local(0.1)
	var cols: Array = RUBBLE.get(rec.material, RUBBLE.ziegel)
	var n := 70 * int(data.w) * int(data.h) + 40
	for i in n:
		var u := rng.randf()
		var v := rng.randf()
		var p: Vector2 = fp[0] + (fp[1] - fp[0]) * u + (fp[3] - fp[0]) * v
		# Der Haufen ist in der Mitte höher
		var mid := 1.0 - maxf(absf(u - 0.5), absf(v - 0.5)) * 2.0
		var lift := roundf(mid * rng.randf_range(2.0, 7.0))
		var col: Color = cols[rng.randi() % cols.size()]
		if rng.randf() < 0.12:
			col = Pal.GRASS if rng.randf() < 0.5 else Pal.MOSS
		_rubble.append({"p": (p + Vector2(0, -lift)).round(), "w": rng.randi_range(1, 3), "h": rng.randi_range(1, 2),
			"col": col, "at": rng.randf() * 0.9 + 0.05})
	_rubble.sort_custom(func(a, b): return a.p.y < b.p.y)


## Setzt Alter, Farbton und Schnee. Parameter werden nur geschrieben, wenn sie sich ändern.
func apply(year: float, tint: Color, snow: float) -> void:
	f = model.factors(rec, year)
	mat.set_shader_parameter("tint", tint)
	for k in ["age", "moss", "vine", "rust", "holes", "collapse"]:
		var v: float = snappedf(float(f[k]), 0.004)
		if not _last.has(k) or _last[k] != v:
			_last[k] = v
			mat.set_shader_parameter(k, v)
	var sn := snappedf(snow, 0.02)
	if not _last.has("snow") or _last.snow != sn:
		_last.snow = sn
		mat.set_shader_parameter("snow", sn)
	height_factor = 1.0 - 0.85 * float(f.collapse)
	status = {"occupied": model.occupied(rec, year), "active": model.occupied(rec, year) and model.powered(year), "needs": []}
	glow.visible = model.powered(year) and float(f.collapse) < 0.5
	var q := snappedf(float(f.collapse), 0.03)
	if q != _rubble_q:
		_rubble_q = q
		queue_redraw()


func _draw() -> void:
	super._draw()
	var c := float(f.get("collapse", 0.0))
	if c <= 0.01:
		return
	for r in _rubble:
		if float(r.at) > c * 1.15:
			continue
		draw_rect(Rect2(r.p, Vector2(r.w, r.h)), r.col)
