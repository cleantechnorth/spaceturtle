extends Area2D
# ──────────────────────────────────────────────────────────────────────────────
# PetalBoss – the Petal boss for Level 3
#
# Sways side-to-side and slowly rotates so the petals look alive.
# Flashes white when hit.  Scales up and fades out when defeated.
# HP tracking and defeat logic are handled by level3.gd.
# ──────────────────────────────────────────────────────────────────────────────

var _initial_x := 0.0
var _time      := 0.0


func _ready() -> void:
	_initial_x = position.x


func _process(delta: float) -> void:
	_time += delta
	# Sway left-right around the starting x position
	position.x = _initial_x + sin(_time * 0.70) * 70.0
	# Gentle petal-spinning rotation
	rotation = sin(_time * 1.10) * 0.14


# White flash when a reflected petal connects.
func flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(3.0, 3.0, 3.0), 0.07)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.22)


# Scale-up and fade-out death animation.
func explode() -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale",      Vector2(2.8, 2.8), 0.55)
	tween.tween_property(self, "modulate:a", 0.0,               0.55)
	get_tree().create_timer(0.60).timeout.connect(queue_free)
