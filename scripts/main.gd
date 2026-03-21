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

const GEARS_TO_WIN  := 10     # Collect this many gears to win
const NUM_GEARS     := 10     # How many gears to spawn
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


func _ready() -> void:
	start_pos = player.position   # Remember the player's starting spot
	win_label.hide()
	_update_score()

	# Build a random starfield
	var vp := get_viewport_rect().size
	for _i in range(80):
		_star_positions.append(Vector2(randf_range(0.0, vp.x), randf_range(0.0, vp.y)))
		_star_sizes.append(randf_range(0.8, 2.2))
	queue_redraw()   # Draw the stars once; they stay drawn until next queue_redraw

	# Spawn all gears and asteroids
	for _i in range(NUM_GEARS):
		_spawn_gear()
	for _i in range(NUM_ASTEROIDS):
		_spawn_asteroid()


# Draw the starfield.  Called once after queue_redraw() in _ready().
func _draw() -> void:
	for i in _star_positions.size():
		draw_circle(_star_positions[i], _star_sizes[i], Color(1.0, 1.0, 1.0, 0.7))


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
	# Listen for when the player touches this asteroid
	rock.body_entered.connect(_on_asteroid_touched)


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
		win_label.show()


# Fires when a physics body (our player) enters an asteroid's area.
func _on_asteroid_touched(body: Node2D) -> void:
	if body == player and not game_won:
		# Send the turtle back to the start
		player.position = start_pos
		player.velocity  = Vector2.ZERO


# ── Helpers ───────────────────────────────────────────────────────────────────

func _update_score() -> void:
	score_label.text = "Gears: %d / %d" % [score, GEARS_TO_WIN]


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
