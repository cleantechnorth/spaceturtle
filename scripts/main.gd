extends Node2D
# ──────────────────────────────────────────────────────────────────────────────
# Main – game manager
#
# Handles:
#   • Spawning gears and asteroids at the start
#   • Keeping track of the score
#   • Detecting win condition (10 gears collected)
#   • Sending the player back to start when hit by an asteroid
#   • Drawing a simple starfield background
# ──────────────────────────────────────────────────────────────────────────────

const GEARS_TO_WIN  := 15     # Collect this many gears to win
const NUM_GEARS     := 15     # How many gears to spawn
const NUM_ASTEROIDS := 6      # How many asteroids to spawn

# References to nodes already in the scene
@onready var player          : CharacterBody2D = $Player
@onready var gears_node      : Node2D          = $Gears
@onready var asteroids_node  : Node2D          = $Asteroids
@onready var score_label     : Label           = $UI/ScoreLabel
@onready var win_label       : Label           = $UI/WinLabel

# Scenes we'll create copies (instances) of at runtime
var gear_scene     := preload("res://scenes/Gear.tscn")
var asteroid_scene := preload("res://scenes/Asteroid.tscn")

var score    := 0      # Current number of gears collected
var game_won := false  # Has the player won yet?
var start_pos: Vector2 # Where the player begins (set in _ready)

# Starfield data (computed once, drawn every frame)
var _star_positions := PackedVector2Array()
var _star_sizes     := PackedFloat32Array()
var _star_colors    := []   # Array of Color

# Nebula blob data: [position, radius, color]
var _nebula := []


func _ready() -> void:
	start_pos = player.position   # Remember the player's starting spot
	win_label.hide()
	_update_score()

	var vp := get_viewport_rect().size

	# ── Nebula blobs (large semi-transparent coloured circles) ──
	_nebula = [
		[Vector2(vp.x * 0.72, vp.y * 0.28), 220.0, Color(0.30, 0.08, 0.55, 0.13)],
		[Vector2(vp.x * 0.78, vp.y * 0.40), 160.0, Color(0.18, 0.08, 0.65, 0.10)],
		[Vector2(vp.x * 0.65, vp.y * 0.55), 130.0, Color(0.40, 0.10, 0.55, 0.09)],
		[Vector2(vp.x * 0.20, vp.y * 0.60), 180.0, Color(0.35, 0.12, 0.45, 0.10)],
		[Vector2(vp.x * 0.50, vp.y * 0.50), 260.0, Color(0.08, 0.15, 0.50, 0.07)],
		[Vector2(vp.x * 0.10, vp.y * 0.25), 140.0, Color(0.20, 0.05, 0.60, 0.08)],
	]

	# ── Starfield: 120 stars with colour tints ──
	# Star colour palette: mostly white/blue-white, some warm yellow
	var palettes := [
		Color(1.00, 1.00, 1.00, 0.90),   # pure white
		Color(0.85, 0.92, 1.00, 0.85),   # blue-white
		Color(0.75, 0.88, 1.00, 0.80),   # cool blue
		Color(1.00, 0.95, 0.80, 0.80),   # warm yellow
		Color(1.00, 0.80, 0.70, 0.70),   # faint orange (red giant)
	]
	for _i in range(120):
		_star_positions.append(Vector2(randf_range(0.0, vp.x), randf_range(0.0, vp.y)))
		_star_sizes.append(randf_range(0.6, 2.4))
		_star_colors.append(palettes[randi() % palettes.size()])

	queue_redraw()

	# Spawn all gears and asteroids
	for _i in range(NUM_GEARS):
		_spawn_gear()
	for _i in range(NUM_ASTEROIDS):
		_spawn_asteroid()


# Draw the nebula + starfield.  Called once after queue_redraw() in _ready().
func _draw() -> void:
	var vp := get_viewport_rect().size

	# Solid deep-space background (slightly lighter than default clear colour)
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.04, 0.02, 0.12, 1.0))

	# Nebula blobs
	for blob in _nebula:
		draw_circle(blob[0], blob[1], blob[2])

	# Stars
	for i in _star_positions.size():
		var sz: float = _star_sizes[i]
		draw_circle(_star_positions[i], sz, _star_colors[i])
		# Add a tiny cross-flare on the largest stars
		if sz > 1.9:
			var p  := _star_positions[i]
			var c  := Color(_star_colors[i].r, _star_colors[i].g, _star_colors[i].b, 0.35)
			draw_line(p + Vector2(-sz * 2.5, 0), p + Vector2(sz * 2.5, 0), c, 0.6)
			draw_line(p + Vector2(0, -sz * 2.5), p + Vector2(0, sz * 2.5), c, 0.6)


# ── Spawning ──────────────────────────────────────────────────────────────────

func _spawn_gear() -> void:
	var gear: Area2D = gear_scene.instantiate()
	gear.position = _random_pos()
	gears_node.add_child(gear)
	# Listen for when the player touches this gear
	# .bind(gear) passes the gear itself as an extra argument to the callback
	gear.body_entered.connect(_on_gear_touched.bind(gear))


func _spawn_asteroid() -> void:
	var rock: Area2D = asteroid_scene.instantiate()
	rock.position = _random_pos()
	asteroids_node.add_child(rock)


# ── Event callbacks ───────────────────────────────────────────────────────────

# Fires when a physics body (our player) enters a gear's area.
func _on_gear_touched(body: Node2D, gear: Area2D) -> void:
	# Safety checks: gear still exists, not already collected, game still going
	if not is_instance_valid(gear) or gear.collected or game_won:
		return
	if body != player:
		return

	score += 1
	_update_score()
	gear.collect()        # Play the pop animation and disappear

	# Check win condition
	if score >= GEARS_TO_WIN:
		game_won = true
		_do_transition()


# Check asteroid proximity every frame – more reliable than body_entered signals.
func _process(_delta: float) -> void:
	if game_won:
		return
	for rock in asteroids_node.get_children():
		# Combined radius: player 22 px + asteroid 24 px = 46 px
		if rock.global_position.distance_to(player.global_position) < 46.0:
			player.position = start_pos
			player.velocity  = Vector2.ZERO
			break


# ── Helpers ───────────────────────────────────────────────────────────────────

func _update_score() -> void:
	score_label.text = "Gears: %d / %d" % [score, GEARS_TO_WIN]


# Fades to black, shows the Level 2 title, then loads Earth Isles.
func _do_transition() -> void:
	# Full-screen black overlay added to UI so it's always on top
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	$UI.add_child(overlay)

	# "Earth Isles" title card
	var title := Label.new()
	title.text = "Level 2\nEarth Isles"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.6, 1.0, 0.4, 1.0))
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left   = -240.0
	title.offset_top    = -60.0
	title.offset_right  =  240.0
	title.offset_bottom =  60.0
	title.modulate      = Color(1.0, 1.0, 1.0, 0.0)
	$UI.add_child(title)

	# Sequence: fade screen to black → reveal title → pause → load Level 2
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 1.2)
	tween.tween_property(title, "modulate:a", 1.0, 0.6)
	tween.tween_interval(1.8)
	tween.tween_callback(
		func() -> void: get_tree().change_scene_to_file("res://scenes/Level2.tscn")
	)


# Returns a random position on screen that isn't too close to the player start.
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
