extends Node2D
class_name BaseLevel
# ──────────────────────────────────────────────────────────────────────────────
# BaseLevel – shared game-loop logic for every level
#
# To add a new level:
#   1. Create a scene with nodes: Player, Gears (Node2D), UI (CanvasLayer),
#      UI/ScoreLabel (Label).
#   2. Attach a script that extends BaseLevel.
#   3. Override the four hooks below.  Everything else is handled here.
#
# Hooks (override in your level script):
#   _configure()          – set level vars (gears_to_win, next_scene_path, …)
#   _level_setup()        – build background data arrays, connect extra signals
#   _spawn_collectibles() – default: spawn num_gears gears; add enemies here
#   _draw()               – draw the unique background each frame
# ──────────────────────────────────────────────────────────────────────────────

# ── Level configuration – set these inside _configure() ──────────────────────
var next_scene_path  := ""                          # "" = no transition (final level)
var gears_to_win     := 15
var num_gears        := 15
var gear_spawn_scale := Vector2.ONE
var transition_title := "Level Complete!"
var transition_color := Color(1.0, 0.9, 0.1, 1.0)
var collectible_name := "Gears"                     # shown in the HUD label

# ── Shared node references (resolved from scene tree) ────────────────────────
@onready var player      : CharacterBody2D = $Player
@onready var gears_node  : Node2D          = $Gears
@onready var score_label : Label           = $UI/ScoreLabel

var gear_scene := preload("res://scenes/Gear.tscn")

# ── Shared runtime state ──────────────────────────────────────────────────────
var _score    := 0
var _won      := false
var _start_pos: Vector2


func _ready() -> void:
	_configure()
	_start_pos = player.position
	_update_score()
	_level_setup()
	queue_redraw()
	_spawn_collectibles()


# ── Overrideable hooks ────────────────────────────────────────────────────────

## Set level-specific variables before anything else runs.
func _configure() -> void:
	pass


## Build background decoration data and connect any extra signals.
## Called after _configure(), before queue_redraw() and _spawn_collectibles().
func _level_setup() -> void:
	pass


## Spawn gears and hazards.
## Default behaviour: spawn num_gears gears at gear_spawn_scale.
func _spawn_collectibles() -> void:
	for _i in range(num_gears):
		_spawn_gear(gear_spawn_scale)


# ── Shared helpers ────────────────────────────────────────────────────────────

## Instantiate one gear, place it at a random safe position, wire up signal.
func _spawn_gear(scale: Vector2 = Vector2.ONE) -> void:
	var gear: Area2D = gear_scene.instantiate()
	gear.position = _random_pos()
	gear.scale    = scale
	gears_node.add_child(gear)
	gear.body_entered.connect(_on_gear_touched.bind(gear))


## Fired when the player's physics body enters a gear's Area2D.
func _on_gear_touched(body: Node2D, gear: Area2D) -> void:
	if not is_instance_valid(gear) or gear.collected or _won:
		return
	if body != player:
		return
	_score += 1
	_update_score()
	gear.collect()
	if _score >= gears_to_win:
		_won = true
		_do_transition()


## Fade to black, show the next-level title card, then load next_scene_path.
func _do_transition() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	$UI.add_child(overlay)

	var title := Label.new()
	title.text = transition_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", transition_color)
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left   = -290.0
	title.offset_top    = -70.0
	title.offset_right  =  290.0
	title.offset_bottom =  70.0
	title.modulate      = Color(1.0, 1.0, 1.0, 0.0)
	$UI.add_child(title)

	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 1.2)
	tween.tween_property(title,   "modulate:a", 1.0, 0.6)
	tween.tween_interval(1.8)
	if next_scene_path != "":
		tween.tween_callback(
			func() -> void: get_tree().change_scene_to_file(next_scene_path)
		)


func _update_score() -> void:
	if is_instance_valid(score_label):
		score_label.text = "%s: %d / %d" % [collectible_name, _score, gears_to_win]


## Returns a random on-screen position at least 120 px from the player start.
func _random_pos() -> Vector2:
	var vp  := get_viewport_rect().size
	var pos := Vector2.ZERO
	while true:
		pos = Vector2(
			randf_range(60.0, vp.x - 60.0),
			randf_range(60.0, vp.y - 60.0)
		)
		if pos.distance_to(_start_pos) > 120.0:
			break
	return pos
