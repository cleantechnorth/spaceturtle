extends BaseLevel
# ──────────────────────────────────────────────────────────────────────────────
# Level 1 – Space
#
# Background: deep space starfield with nebula blobs.
# Hazards:    6 asteroids that reset the player on contact.
# Goal:       collect 15 gears.
# ──────────────────────────────────────────────────────────────────────────────

const NUM_ASTEROIDS := 6

var asteroid_scene := preload("res://scenes/Asteroid.tscn")

# Starfield / nebula data (built once in _level_setup)
var _star_positions := PackedVector2Array()
var _star_sizes     := PackedFloat32Array()
var _star_colors    := []
var _nebula         := []


# ── Configuration ─────────────────────────────────────────────────────────────

func _configure() -> void:
	gears_to_win     = 15
	num_gears        = 15
	next_scene_path  = "res://scenes/Level2.tscn"
	transition_title = "Level 2\nEarth Isles"
	transition_color = Color(0.6, 1.0, 0.4, 1.0)


# ── Level setup ───────────────────────────────────────────────────────────────

func _level_setup() -> void:
	var vp := get_viewport_rect().size

	_nebula = [
		[Vector2(vp.x * 0.72, vp.y * 0.28), 220.0, Color(0.30, 0.08, 0.55, 0.13)],
		[Vector2(vp.x * 0.78, vp.y * 0.40), 160.0, Color(0.18, 0.08, 0.65, 0.10)],
		[Vector2(vp.x * 0.65, vp.y * 0.55), 130.0, Color(0.40, 0.10, 0.55, 0.09)],
		[Vector2(vp.x * 0.20, vp.y * 0.60), 180.0, Color(0.35, 0.12, 0.45, 0.10)],
		[Vector2(vp.x * 0.50, vp.y * 0.50), 260.0, Color(0.08, 0.15, 0.50, 0.07)],
		[Vector2(vp.x * 0.10, vp.y * 0.25), 140.0, Color(0.20, 0.05, 0.60, 0.08)],
	]

	var palettes := [
		Color(1.00, 1.00, 1.00, 0.90),
		Color(0.85, 0.92, 1.00, 0.85),
		Color(0.75, 0.88, 1.00, 0.80),
		Color(1.00, 0.95, 0.80, 0.80),
		Color(1.00, 0.80, 0.70, 0.70),
	]
	for _i in range(120):
		_star_positions.append(Vector2(randf_range(0.0, vp.x), randf_range(0.0, vp.y)))
		_star_sizes.append(randf_range(0.6, 2.4))
		_star_colors.append(palettes[randi() % palettes.size()])


# ── Spawning ──────────────────────────────────────────────────────────────────

func _spawn_collectibles() -> void:
	for _i in range(num_gears):
		_spawn_gear()
	for _i in range(NUM_ASTEROIDS):
		var rock: Area2D = asteroid_scene.instantiate()
		rock.position = _random_pos()
		$Asteroids.add_child(rock)


# ── Per-frame: asteroid proximity check ───────────────────────────────────────

func _process(_delta: float) -> void:
	if _won:
		return
	for rock in $Asteroids.get_children():
		# Combined radius: player 22 px + asteroid 24 px = 46 px
		if rock.global_position.distance_to(player.global_position) < 46.0:
			player.position = _start_pos
			player.velocity  = Vector2.ZERO
			break


# ── Background drawing ────────────────────────────────────────────────────────

func _draw() -> void:
	var vp := get_viewport_rect().size

	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.04, 0.02, 0.12, 1.0))

	for blob in _nebula:
		draw_circle(blob[0], blob[1], blob[2])

	for i in _star_positions.size():
		var sz: float = _star_sizes[i]
		draw_circle(_star_positions[i], sz, _star_colors[i])
		if sz > 1.9:
			var p := _star_positions[i]
			var c := Color(_star_colors[i].r, _star_colors[i].g, _star_colors[i].b, 0.35)
			draw_line(p + Vector2(-sz * 2.5, 0), p + Vector2(sz * 2.5, 0), c, 0.6)
			draw_line(p + Vector2(0, -sz * 2.5), p + Vector2(0, sz * 2.5), c, 0.6)
