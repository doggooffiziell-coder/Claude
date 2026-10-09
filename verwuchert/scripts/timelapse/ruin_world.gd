class_name RuinWorld
extends Node2D
## Die Stadt aus Phase 1 im Zeitraffer. Diese Klasse spielt für die Spielklassen die Rolle des CityBuilder
## (speed, anim_time, night, hour, particles, building_views, tree_views, pole_views), darum sind Gebäude,
## Bäume, Schatten und Rauch dieselben wie im Stadtbau. Der Verfall kommt aus DecayModel und den Shadern.
##
## Aufbau in Häppchen: step(budget_ms) gibt true zurück, wenn alles steht. So bleibt der Ladebalken lebendig.

const T := 32
const MARGIN := 4

var model: DecayModel
var city: Dictionary
var entry_row := 8
var speed := 1.0
var anim_time := 0.0
var night := 0.0
var hour := 12.0
var particles: Particles
var building_views := {}
var tree_views: Array[TreeView] = []
var pole_views: Array[PoleView] = []
var roads := {}
var progress := 0.0
var label := ""
var done := false
var year := 0.0

var ground: RuinGround
var objects: Node2D
var shadows: CanvasGroup
var _lit_mat: ShaderMaterial
var _ground_mat: ShaderMaterial
var _job: GroundJob
var _stage := 0
var _queue: Array = []
var _qi := 0
var _plants: Array = []
var _cliff_bits: Array = []
var _pond: PackedByteArray


func _init() -> void:
	y_sort_enabled = false


## Bereitet alles vor. Danach ruft man step() bis es true meldet.
func begin(decay: DecayModel) -> void:
	model = decay
	city = decay.city
	entry_row = int(city.h) / 2
	_pond = Terrain.ponds(int(city.seed), int(city.w), int(city.h), Config.integer("city/pond_count", 1))
	_lit_mat = ShaderMaterial.new()
	_lit_mat.shader = preload("res://shaders/lit.gdshader")
	material = _lit_mat
	_job = GroundJob.new(int(city.seed), int(city.w), int(city.h), MARGIN, _pond)
	ground = RuinGround.new()
	add_child(ground)
	shadows = CanvasGroup.new()
	shadows.fit_margin = 0.0
	shadows.clear_margin = 0.0
	add_child(shadows)
	var sp := ShadowPainter.new()
	sp.builder = self
	shadows.add_child(sp)
	objects = Node2D.new()
	objects.y_sort_enabled = true
	objects.use_parent_material = true
	add_child(objects)
	particles = Particles.new()
	particles.use_parent_material = true
	add_child(particles)
	_cliff_bits = IsoCliff.make_bits(_rng(3), 44)
	label = "Der Boden wird gemalt"


func _rng(extra: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = int(city.seed) + extra
	return r


## Gibt true zurück, wenn die Welt fertig ist.
func step(budget_ms: float) -> bool:
	if done:
		return true
	match _stage:
		0:
			if _job.step(budget_ms):
				_finish_ground()
				_make_queue()
				_stage = 1
				label = "Die Stadt entsteht aus der Erinnerung"
			progress = _job.progress * 0.5
		1:
			var t0 := Time.get_ticks_usec()
			while _qi < _queue.size() and float(Time.get_ticks_usec() - t0) < budget_ms * 1000.0:
				_queue[_qi].call()
				_qi += 1
			progress = 0.5 + 0.5 * float(_qi) / maxf(1.0, _queue.size())
			if _qi >= _queue.size():
				done = true
				progress = 1.0
				queue_redraw()
	return done


# Boden

func _road_any(t: Vector2i) -> bool:
	if t.y == entry_row and t.x < 0 and t.x >= -MARGIN:
		return true
	return roads.has(t)


func road_mask(t: Vector2i) -> int:
	var m := 0
	if _road_any(t + Vector2i(0, -1)): m |= RoadArt.N
	if _road_any(t + Vector2i(1, 0)): m |= RoadArt.E
	if _road_any(t + Vector2i(0, 1)): m |= RoadArt.S
	if _road_any(t + Vector2i(-1, 0)): m |= RoadArt.W
	return m


func _finish_ground() -> void:
	var img: Image = _job.image
	var gw := img.get_width()
	var gh := img.get_height()
	for b in city.buildings:
		if b.type == "road" and str(b.get("state", "done")) == "done":
			roads[Vector2i(int(b.x), int(b.y))] = b
	var mask := Image.create_empty(gw, gh, false, Image.FORMAT_R8)
	var white := Color(1, 1, 1, 1)
	for k in MARGIN:
		var pos := Vector2i(k * T, (entry_row + MARGIN) * T)
		img.blit_rect(SpriteFactory.road_image(RoadArt.E | RoadArt.W, k + 1), Rect2i(0, 0, T, T), pos)
		mask.fill_rect(Rect2i(pos, Vector2i(T, T)), white)
	for t in roads:
		var pos2 := Vector2i((t.x + MARGIN) * T, (t.y + MARGIN) * T)
		img.blit_rect(SpriteFactory.road_image(road_mask(t), (t.x * 7 + t.y * 13) % 6), Rect2i(0, 0, T, T), pos2)
		mask.fill_rect(Rect2i(pos2, Vector2i(T, T)), white)
	var w: int = city.w
	var h: int = city.h
	var hs := Terrain.heights_margin(int(city.seed), w, h, MARGIN)
	var himg := Image.create_empty(w + MARGIN * 2, h + MARGIN * 2, false, Image.FORMAT_R8)
	for y in h + MARGIN * 2:
		for x in w + MARGIN * 2:
			var v := clampf(hs[y * (w + MARGIN * 2) + x], 0.0, 1.0)
			himg.set_pixel(x, y, Color(v, v, v, 1))
	_ground_mat = ShaderMaterial.new()
	_ground_mat.shader = preload("res://shaders/ruin_ground.gdshader")
	_ground_mat.set_shader_parameter("road_mask", ImageTexture.create_from_image(mask))
	_ground_mat.set_shader_parameter("height_map", ImageTexture.create_from_image(himg))
	ground.material = _ground_mat
	ground.tex = ImageTexture.create_from_image(img)
	ground.offset = Vector2(-MARGIN * T, -MARGIN * T)
	ground.queue_redraw()


# Gebäude, Bäume und Pflanzen

func _make_queue() -> void:
	for b in city.buildings:
		if b.type == "road" or str(b.get("state", "done")) != "done":
			continue
		_queue.append(_add_building.bind(b))
	for t in city.trees:
		_queue.append(_add_tree.bind(t, false))
	var forest := ForestPlan.make(city, MARGIN, entry_row)
	for i in range(0, forest.size(), 24):
		_queue.append(_add_forest.bind(forest.slice(i, i + 24)))
	for p in model.plants:
		_queue.append(_add_plant.bind(p))


func _add_building(b: Dictionary) -> void:
	var v := RuinView.new()
	objects.add_child(v)
	v.setup(b, self)
	v.attach(model, model.recs[int(b.id)])
	building_views[int(b.id)] = v


func _add_tree(t: Dictionary, decor: bool) -> TreeView:
	var tv := TreeView.new()
	objects.add_child(tv)
	tv.setup(t, self, decor)
	if not decor:
		tree_views.append(tv)
	return tv


func _add_forest(list: Array) -> void:
	for t in list:
		_add_tree(t, true)


func _add_plant(p: Dictionary) -> void:
	var d := {"x": p.x, "y": p.y, "ox": p.ox, "oy": p.oy, "seed": p.seed, "kind": "sapling"}
	var tv := _add_tree(d, false)
	tv.visible = false
	_plants.append({"p": p, "view": tv})


# Ablauf

## Stellt Jahr, Tageszeit und Jahreszeit ein. Das ist der ganze Zeitablauf, alles andere folgt daraus.
func set_time(y: float, hour_value: float, season: float) -> void:
	year = y
	hour = hour_value
	night = DayCycle.night(hour)
	var tint := DayCycle.tint(hour) * DecayModel.season_tint(season)
	var snow := DecayModel.snow(season)
	_lit_mat.set_shader_parameter("tint", tint)
	_ground_mat.set_shader_parameter("tint", tint)
	_ground_mat.set_shader_parameter("cover", snappedf(model.grass_cover(y), 0.004))
	_ground_mat.set_shader_parameter("water", snappedf(model.water_level(y), 0.002))
	_ground_mat.set_shader_parameter("snow", snappedf(snow, 0.02))
	_ground_mat.set_shader_parameter("time", anim_time)
	shadows.visible = Settings.shadows
	shadows.self_modulate = Color(1, 1, 1, 0.34 * DayCycle.sun_strength(hour))
	for v in building_views.values():
		v.apply(y, tint, snow)
	for e in _plants:
		var kind := model.plant_kind(e.p, y)
		var tv: TreeView = e.view
		if kind == "":
			tv.visible = false
		else:
			tv.visible = true
			tv.regrow(kind)


func _process(delta: float) -> void:
	anim_time += delta


func _draw() -> void:
	if not done:
		return
	IsoCliff.draw(self, int(city.w), int(city.h), MARGIN, _cliff_bits, 44)


## Rechteck der ganzen Karte mit Rand auf dem Bildschirm.
func map_screen_rect() -> Rect2:
	var w: int = city.w
	var h: int = city.h
	var top := Iso.to_screen(-MARGIN, -MARGIN)
	var right := Iso.to_screen(w + MARGIN, -MARGIN)
	var bot := Iso.to_screen(w + MARGIN, h + MARGIN)
	var left := Iso.to_screen(-MARGIN, h + MARGIN)
	return Rect2(left.x, top.y, right.x - left.x, bot.y - top.y)
