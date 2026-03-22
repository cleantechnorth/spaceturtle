extends Area2D
# ──────────────────────────────────────────────────────────────────────────────
# ShieldPickup – a brass shield the player can grab in Level 3
#
# Spins gently in place.  When the player touches it, it plays a pop animation
# and disappears.  level3.gd connects body_entered and sets player.has_shield.
# ──────────────────────────────────────────────────────────────────────────────

const SPIN_SPEED := 1.2   # Radians per second
var   collected  := false


func _process(delta: float) -> void:
	rotation += SPIN_SPEED * delta


# Called by level3.gd when the player overlaps the pickup.
func collect() -> void:
	if collected:
		return
	collected = true

	$CollisionShape2D.set_deferred("disabled", true)

	# Pop: scale up and fade out
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale",      Vector2(2.2, 2.2), 0.28)
	tween.tween_property(self, "modulate:a", 0.0,               0.28)

	get_tree().create_timer(0.32).timeout.connect(queue_free)
