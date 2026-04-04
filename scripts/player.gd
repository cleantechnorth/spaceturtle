extends CharacterBody2D
# ──────────────────────────────────────────────────────────────────────────────
# Player – steampunk space turtle
#
# WASD or arrow keys move the turtle.
# Floaty space physics: the turtle accelerates gradually and keeps drifting
# a little after you let go, like floating in zero gravity.
# ──────────────────────────────────────────────────────────────────────────────

var has_shield := false   # Set to true by level3.gd when shield is collected

func _ready() -> void:
	# Apply the colour tint chosen in the Turtle Icon Editor
	$Sprite.modulate = TurtleSettings.turtle_modulate

const ACCELERATION := 600.0   # How quickly the turtle speeds up
const MAX_SPEED    := 260.0   # The fastest it can go
const FRICTION     := 0.92    # How quickly it slows down
                               # (0 = instant stop, 1 = never stops)

func _physics_process(delta: float) -> void:
	# Read which keys are held – read raw key state to avoid action-map issues
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1.0
	if dir.length() > 1.0:
		dir = dir.normalized()

	# Push the turtle in that direction
	velocity += dir * ACCELERATION * delta

	# Cap speed so it doesn't go too fast
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED

	# Apply space drag for that floaty feel
	velocity *= FRICTION

	# Actually move the turtle (handles wall collisions automatically)
	move_and_slide()

	# Keep the turtle inside the screen
	var vp := get_viewport_rect().size
	position = position.clamp(Vector2(30.0, 30.0), vp - Vector2(30.0, 30.0))

	# Smoothly rotate the turtle to face the direction it's moving
	if velocity.length() > 8.0:
		rotation = lerp_angle(rotation, velocity.angle(), 0.12)
