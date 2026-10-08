class_name Particles
extends Node2D
## Leichtes Partikelsystem in Pixeln: Rauch, Dampf, Staub, Blätter, Funken, schwebende Zahlen.

const MAX := 900

var wind := Vector2(5.0, 0.0)
var _parts: Array[Dictionary] = []
var _font: Font


func _ready() -> void:
	_font = PixelFont.font()


func emit(kind: String, pos: Vector2, count: int = 1, opts: Dictionary = {}) -> void:
	if not Settings.particles and kind != "text":
		return
	for i in count:
		if _parts.size() >= MAX:
			_parts.pop_front()
		var p := {"kind": kind, "pos": pos, "vel": Vector2.ZERO, "age": 0.0, "life": 1.0,
			"seed": randf() * 100.0, "z": 0.0, "vz": 0.0}
		match kind:
			"smoke":
				p.pos += Vector2(randf_range(-1, 1), 0)
				p.vel = Vector2(randf_range(-1.5, 1.5), randf_range(-11.0, -8.0))
				p.life = randf_range(2.6, 3.6) * float(opts.get("life", 1.0))
				p.sz = float(opts.get("size", 1.0))
				p.dark = bool(opts.get("dark", false))
			"steam":
				p.pos += Vector2(randf_range(-5, 5), 0)
				p.vel = Vector2(randf_range(-2, 2), randf_range(-14.0, -10.0))
				p.life = randf_range(2.8, 3.8)
				p.sz = 1.6
			"dust":
				p.vel = Vector2(randf_range(-14, 14), randf_range(-16, -4))
				p.life = randf_range(0.5, 0.9)
				p.col = [Pal.SAND, Pal.WOOD_L, Pal.STONE_L, Pal.BONE][randi() % 4]
			"leaf":
				p.z = float(opts.get("z", randf_range(10, 24)))
				p.vel = Vector2(randf_range(-3, 3), 0) + wind * 0.6
				p.vz = -randf_range(5.0, 8.0)
				p.life = 99.0
				p.rest = 0.0
				p.col = opts.get("col", [Pal.GRASS_L, Pal.LEAF_L, Pal.GRASS, Pal.OCHRE][randi() % 4])
			"spark":
				var ang := randf() * TAU
				p.vel = Vector2(cos(ang), sin(ang) * 0.6 - 0.8) * randf_range(16, 34)
				p.life = randf_range(0.5, 0.9)
				p.col = [Pal.YELLOW, Pal.WHITE, Pal.OCHRE][randi() % 3]
			"drop":
				p.vel = Vector2(randf_range(-4, 4), randf_range(-14, -8))
				p.life = 0.55
				p.col = [Pal.SKY, Pal.WHITE, Pal.WATER][randi() % 3]
			"text":
				p.text = str(opts.get("text", ""))
				p.col = opts.get("col", Pal.YELLOW)
				p.vel = Vector2(0, -14)
				p.life = float(opts.get("life", 1.4))
		_parts.append(p)


var _had := false


func _process(delta: float) -> void:
	if _parts.is_empty():
		if _had:
			_had = false
			queue_redraw()
		return
	_had = true
	var keep: Array[Dictionary] = []
	for p in _parts:
		p.age += delta
		match p.kind:
			"smoke", "steam":
				p.vel += wind * delta * 0.5
				p.vel.y *= (1.0 - delta * 0.15)
				p.pos += p.vel * delta + Vector2(sin(p.age * 2.0 + p.seed) * 3.0 * delta, 0)
			"dust", "spark", "drop":
				p.vel.y += (40.0 if p.kind != "spark" else 30.0) * delta
				p.pos += p.vel * delta
			"leaf":
				if p.z > 0.0:
					p.z += p.vz * delta
					p.pos += (p.vel + Vector2(sin(p.age * 3.0 + p.seed) * 9.0, 0)) * delta
					if p.z <= 0.0:
						p.z = 0.0
						p.rest = p.age
				elif p.age - p.rest > 2.5:
					p.age = p.life
			"text":
				p.vel.y *= (1.0 - delta * 2.5)
				p.pos += p.vel * delta
		if p.age < p.life:
			keep.append(p)
	_parts = keep
	queue_redraw()


func _draw() -> void:
	for p in _parts:
		var t: float = p.age / p.life
		var pos: Vector2 = (p.pos as Vector2).round()
		match p.kind:
			"smoke":
				var r: float = (1.0 + t * 3.5) * p.sz
				var col := Pal.STONE if p.dark else Pal.STONE_L
				if t > 0.5:
					col = Pal.STONE_D if p.dark else Pal.STONE
				draw_circle(pos, roundf(r), Pal.a(col, 0.55 * (1.0 - t)))
				if r > 2.0:
					draw_circle(pos + Vector2(-1, -1), roundf(r * 0.5), Pal.a(Pal.BONE if not p.dark else Pal.STONE, 0.35 * (1.0 - t)))
			"steam":
				var r2: float = (2.0 + t * 5.0) * p.sz
				draw_circle(pos, roundf(r2), Pal.a(Pal.BONE, 0.5 * (1.0 - t)))
				draw_circle(pos + Vector2(-1, -1), roundf(r2 * 0.6), Pal.a(Pal.WHITE, 0.4 * (1.0 - t)))
			"dust":
				draw_rect(Rect2(pos, Vector2.ONE * (2 if t < 0.4 else 1)), Pal.a(p.col, 1.0 - t))
			"leaf":
				var lp := pos - Vector2(0, roundf(p.z))
				var flip := int(p.age * 6.0 + p.seed) % 2 == 0
				var fade: float = 1.0
				if p.z <= 0.0:
					fade = 1.0 - (p.age - p.rest) / 2.5
				draw_rect(Rect2(lp, Vector2(2 if flip else 1, 1)), Pal.a(p.col, fade))
				if p.z > 0.0:
					draw_rect(Rect2(pos + Vector2(0, 1), Vector2(1, 1)), Pal.a(Pal.BLACK, 0.18))
			"spark":
				draw_rect(Rect2(pos, Vector2.ONE), Pal.a(p.col, 1.0 - t * t))
				if t < 0.3:
					draw_rect(Rect2(pos - p.vel.normalized().round(), Vector2.ONE), Pal.a(p.col, 0.5))
			"drop":
				draw_rect(Rect2(pos, Vector2.ONE), Pal.a(p.col, 1.0 - t))
			"text":
				var alpha := 1.0 if t < 0.7 else (1.0 - (t - 0.7) / 0.3)
				var w := _font.get_string_size(p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE).x
				var tp := pos - Vector2(roundf(w * 0.5), 0)
				draw_string(_font, tp + Vector2(1, 1), p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE, Pal.a(Pal.BLACK, alpha))
				draw_string(_font, tp, p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, PixelFont.SIZE, Pal.a(p.col, alpha))
