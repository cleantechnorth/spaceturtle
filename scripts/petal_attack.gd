extends Area2D
# ──────────────────────────────────────────────────────────────────────────────
# PetalAttack – a petal-blade projectile fired by the Petal boss
#
# Moves in a straight line toward the player's position at launch time.
# If reflected by the player's shield, it reverses direction and turns blue.
# level3.gd connects the body_entered and area_entered signals after spawning.
# ──────────────────────────────────────────────────────────────────────────────

const SPEED := 200.0

var velocity  := Vector2.ZERO
var reflected := false


func launch(target_pos: Vector2) -> void:
	var dir := (target_pos - global_position).normalized()
	velocity = dir * SPEED
	# Orient sprite to point in the direction of travel
	rotation = dir.angle() + PI * 0.5


func _process(delta: float) -> void:
	position += velocity * delta
	rotation   = velocity.angle() + PI * 0.5

	# Destroy once well off-screen so stray petals don't accumulate
	var s := get_viewport_rect().size
	if (position.x < -80 or position.x > s.x + 80 or
		position.y < -80 or position.y > s.y + 80):
		queue_free()


# Called by level3.gd when the player (who has the shield) runs into this petal.
func reflect() -> void:
	reflected = true
	velocity  = -velocity
	rotation  = velocity.angle() + PI * 0.5
	# Turn blue so it's clear this petal is now heading back at the boss
	modulate = Color(0.45, 0.85, 1.0)
