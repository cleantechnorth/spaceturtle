extends Area2D
# ──────────────────────────────────────────────────────────────────────────────
# Gear – collectible item
#
# Spins slowly in place.
# When the player touches it, it plays a "pop" animation (scale up + fade out)
# and then disappears.  main.gd is responsible for keeping the score.
# ──────────────────────────────────────────────────────────────────────────────

const SPIN_SPEED := 1.5        # Radians per second (how fast it spins)
var   collected  := false      # Prevents collecting the same gear twice

func _process(delta: float) -> void:
	# Spin the gear every frame
	rotation += SPIN_SPEED * delta


# Called by main.gd when the player overlaps this gear.
func collect() -> void:
	if collected:
		return          # Already collected – do nothing
	collected = true

	# Turn off collision immediately so nothing else can grab it
	$CollisionShape2D.set_deferred("disabled", true)

	# Pop animation: scale up and fade out at the same time
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale",      Vector2(2.5, 2.5), 0.25)
	tween.tween_property(self, "modulate:a", 0.0,               0.25)

	# Delete the node after the animation finishes (0.3 s)
	get_tree().create_timer(0.3).timeout.connect(queue_free)
