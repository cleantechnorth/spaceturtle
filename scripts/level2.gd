extends Node2D
# ──────────────────────────────────────────────────────────────────────────────
# Level 2 – Earth Isles
#
# Handles:
#   • Drawing a nature background (sky, islands, flowers)
#   • Spawning 30 mini gears scattered across the map
#   • Tracking collection progress
#   • Showing a "Level 3 coming soon" card when all mini gears are found
# ──────────────────────────────────────────────────────────────────────────────

const NUM_MINI_GEARS := 30

@onready var player       : CharacterBody2D = $Player
@onready var gears_node   : Node2D          = $Gears
@onready var score_label  : Label           = $UI/ScoreLabel

var gear_scene := preload("res://scenes/Gear.tscn")

var score    := 0
var game_won := false
var start_pos: Vector2

# Background decoration data (computed once in _ready)
var _islands  := []   # [pos, rx, ry, color]
var _flowers  := []   # [pos, color]
var _clouds   := []   # [pos, width]


func _ready() -> void:
	start_pos = player.position
	_update_score()

	var vp := get_viewport_rect().size

	# ── Islands: large green ellipse-like blobs ──────────────────────────────
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

	# ── Flowers: tiny coloured dots scattered on the islands ─────────────────
	var flower_colors := [
		Color(1.0, 0.3, 0.4, 1.0),   # pink
		Color(1.0, 0.9, 0.2, 1.0),   # yellow
		Color(0.8, 0.2, 1.0, 1.0),   # purple
		Color(1.0, 0.6, 0.1, 1.0),   # orange
		Color(1.0, 1.0, 1.0, 0.9),   # white
	]
	for _i in range(60):
		_flowers.append([
			Vector2(randf_range(20.0, vp.x - 20.0), randf_range(20.0, vp.y - 20.0)),
			flower_colors[randi() % flower_colors.size()],
		])

	# ── Clouds: soft white ovals drifting across the sky ─────────────────────
	for _i in range(8):
		_clouds.append([
			Vector2(randf_range(0.0, vp.x), randf_range(20.0, vp.y * 0.4)),
			randf_range(70.0, 160.0),
		])

	queue_redraw()

	# Spawn all mini gears (half size)
	for _i in range(NUM_MINI_GEARS):
		_spawn_mini_gear()


func _draw() -> void:
	var vp := get_viewport_rect().size

	# Sky gradient background (light blue)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.44, 0.74, 0.94, 1.0))

	# Ocean/water at the bottom third (darker blue)
	var water_y := vp.y * 0.62
	draw_rect(
		Rect2(Vector2(0.0, water_y), Vector2(vp.x, vp.y - water_y)),
		Color(0.14, 0.42, 0.72, 1.0)
	)

	# Clouds
	for cloud in _clouds:
		var p : Vector2 = cloud[0]
		var w : float   = cloud[1]
		draw_circle(p,                w * 0.38, Color(1.0, 1.0, 1.0, 0.80))
		draw_circle(p + Vector2( w * 0.28, 6.0), w * 0.30, Color(1.0, 1.0, 1.0, 0.75))
		draw_circle(p + Vector2(-w * 0.28, 8.0), w * 0.28, Color(1.0, 1.0, 1.0, 0.70))

	# Islands
	for isl in _islands:
		var pos : Vector2 = isl[0]
		var rx  : float   = isl[1]
		var ry  : float   = isl[2]
		var col : Color   = isl[3]
		# Approximate ellipse with overlapping circles
		for t in range(0, 7):
			var a  := t / 6.0 * TAU
			var op := pos + Vector2(cos(a) * rx * 0.5, sin(a) * ry * 0.5)
			draw_circle(op, rx * 0.45, col)
		draw_circle(pos, rx * 0.5, col)

	# Flowers
	for fl in _flowers:
		var fp  : Vector2 = fl[0]
		var fc  : Color   = fl[1]
		# Stem
		draw_line(fp, fp + Vector2(0.0, 8.0), Color(0.2, 0.6, 0.1, 0.9), 1.5)
		# Petals (4 small circles around centre)
		for k in range(4):
			var ang  := k * PI * 0.5
			draw_circle(fp + Vector2(cos(ang), sin(ang)) * 4.0, 3.0, fc)
		draw_circle(fp, 3.0, Color(1.0, 0.95, 0.5, 1.0))


# ── Spawning ──────────────────────────────────────────────────────────────────

func _spawn_mini_gear() -> void:
	var gear: Area2D = gear_scene.instantiate()
	gear.position = _random_pos()
	gear.scale    = Vector2(0.55, 0.55)   # mini!
	gears_node.add_child(gear)
	gear.body_entered.connect(_on_gear_touched.bind(gear))


# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_gear_touched(body: Node2D, gear: Area2D) -> void:
	if not is_instance_valid(gear) or gear.collected or game_won:
		return
	if body != player:
		return

	score += 1
	_update_score()
	gear.collect()

	if score >= NUM_MINI_GEARS:
		game_won = true
		_show_complete()


# ── Helpers ───────────────────────────────────────────────────────────────────

func _update_score() -> void:
	score_label.text = "Mini Gears: %d / %d" % [score, NUM_MINI_GEARS]


func _random_pos() -> Vector2:
	var vp  := get_viewport_rect().size
	var pos := Vector2.ZERO
	while true:
		pos = Vector2(
			randf_range(60.0, vp.x - 60.0),
			randf_range(60.0, vp.y - 60.0)
		)
		if pos.distance_to(start_pos) > 120.0:
			break
	return pos


func _show_complete() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	$UI.add_child(overlay)

	var title := Label.new()
	title.text = "Level 3\nPetal Fields"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.7, 1.0))
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left   = -240.0
	title.offset_top    = -60.0
	title.offset_right  =  240.0
	title.offset_bottom =  60.0
	title.modulate      = Color(1.0, 1.0, 1.0, 0.0)
	$UI.add_child(title)

	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 1.2)
	tween.tween_property(title, "modulate:a", 1.0, 0.6)
	tween.tween_interval(1.8)
	tween.tween_callback(
		func() -> void: get_tree().change_scene_to_file("res://scenes/Level3.tscn")
	)
