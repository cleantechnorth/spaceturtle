extends BaseLevel
# ──────────────────────────────────────────────────────────────────────────────
# Level 2 – Earth Isles
#
# Background: sky, ocean, floating islands, flowers, clouds.
# Goal:       collect 30 mini gears (half-size).
# ──────────────────────────────────────────────────────────────────────────────

var _islands := []   # [pos, rx, ry, color]
var _flowers := []   # [pos, color]
var _clouds  := []   # [pos, width]


# ── Configuration ─────────────────────────────────────────────────────────────

func _configure() -> void:
	gears_to_win     = 30
	num_gears        = 30
	gear_spawn_scale = Vector2(0.55, 0.55)
	collectible_name = "Mini Gears"
	next_scene_path  = "res://scenes/Level3.tscn"
	transition_title = "Level 3\nPetal Fields"
	transition_color = Color(1.0, 0.4, 0.7, 1.0)


# ── Level setup ───────────────────────────────────────────────────────────────

func _level_setup() -> void:
	var vp := get_viewport_rect().size

	var island_colors := [
		Color(0.22, 0.60, 0.20, 1.0),
		Color(0.28, 0.68, 0.22, 1.0),
		Color(0.18, 0.52, 0.18, 1.0),
		Color(0.32, 0.72, 0.28, 1.0),
	]
	for _i in range(7):
		_islands.append([
			Vector2(randf_range(80.0, vp.x - 80.0), randf_range(80.0, vp.y - 80.0)),
			randf_range(60.0, 140.0),
			randf_range(40.0, 90.0),
			island_colors[randi() % island_colors.size()],
		])

	var flower_colors := [
		Color(1.0, 0.3, 0.4, 1.0),
		Color(1.0, 0.9, 0.2, 1.0),
		Color(0.8, 0.2, 1.0, 1.0),
		Color(1.0, 0.6, 0.1, 1.0),
		Color(1.0, 1.0, 1.0, 0.9),
	]
	for _i in range(60):
		_flowers.append([
			Vector2(randf_range(20.0, vp.x - 20.0), randf_range(20.0, vp.y - 20.0)),
			flower_colors[randi() % flower_colors.size()],
		])

	for _i in range(8):
		_clouds.append([
			Vector2(randf_range(0.0, vp.x), randf_range(20.0, vp.y * 0.4)),
			randf_range(70.0, 160.0),
		])


# ── Background drawing ────────────────────────────────────────────────────────

func _draw() -> void:
	var vp := get_viewport_rect().size

	# Sky
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.44, 0.74, 0.94, 1.0))

	# Ocean (bottom third)
	var water_y := vp.y * 0.62
	draw_rect(Rect2(Vector2(0.0, water_y), Vector2(vp.x, vp.y - water_y)),
		Color(0.14, 0.42, 0.72, 1.0))

	# Clouds
	for cloud in _clouds:
		var p : Vector2 = cloud[0]
		var w : float   = cloud[1]
		draw_circle(p,                        w * 0.38, Color(1.0, 1.0, 1.0, 0.80))
		draw_circle(p + Vector2( w * 0.28, 6.0), w * 0.30, Color(1.0, 1.0, 1.0, 0.75))
		draw_circle(p + Vector2(-w * 0.28, 8.0), w * 0.28, Color(1.0, 1.0, 1.0, 0.70))

	# Islands
	for isl in _islands:
		var pos : Vector2 = isl[0]
		var rx  : float   = isl[1]
		var ry  : float   = isl[2]
		var col : Color   = isl[3]
		for t in range(7):
			var a  := t / 6.0 * TAU
			var op := pos + Vector2(cos(a) * rx * 0.5, sin(a) * ry * 0.5)
			draw_circle(op, rx * 0.45, col)
		draw_circle(pos, rx * 0.5, col)

	# Flowers
	for fl in _flowers:
		var fp : Vector2 = fl[0]
		var fc : Color   = fl[1]
		draw_line(fp, fp + Vector2(0.0, 8.0), Color(0.2, 0.6, 0.1, 0.9), 1.5)
		for k in range(4):
			var ang := k * PI * 0.5
			draw_circle(fp + Vector2(cos(ang), sin(ang)) * 4.0, 3.0, fc)
		draw_circle(fp, 3.0, Color(1.0, 0.95, 0.5, 1.0))
