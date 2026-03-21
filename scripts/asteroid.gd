extends Area2D
# ──────────────────────────────────────────────────────────────────────────────
# Asteroid – hazard
#
# Drifts slowly in a random direction and tumbles as it moves.
# Wraps around the screen edges so it never disappears permanently.
# If it hits the player, main.gd sends the turtle back to the start.
# ──────────────────────────────────────────────────────────────────────────────

var drift := Vector2.ZERO   # Direction and speed of the drift

func _ready() -> void:
	# Pick a random direction and speed for this asteroid
	var angle := randf_range(0.0, TAU)             # TAU = full circle in radians
	drift = Vector2(cos(angle), sin(angle)) * randf_range(30.0, 75.0)

func _process(delta: float) -> void:
	# Move in the drift direction
	position += drift * delta

	# Slowly tumble (rotate)
	rotation += 0.6 * delta

	# Wrap around the screen so the asteroid re-enters from the other side
	var s := get_viewport_rect().size
	if   position.x < -35.0:       position.x = s.x + 35.0
	elif position.x > s.x + 35.0:  position.x = -35.0
	if   position.y < -35.0:       position.y = s.y + 35.0
	elif position.y > s.y + 35.0:  position.y = -35.0
