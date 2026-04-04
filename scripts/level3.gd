extends BaseLevel
# ──────────────────────────────────────────────────────────────────────────────
# Level 3 – Petal Fields  (Boss Fight)
#
# Flow:
#   1. Boss (Petal) sways at the top and fires petal-blade attacks every
#      ATTACK_INTERVAL seconds.
#   2. Getting hit without a shield → sent back to start.
#   3. Shield pickup is in the arena; player collects it once.
#   4. With shield: running into a petal reflects it back (turns blue).
#   5. Three reflected hits defeat the boss.
#   6. Boss drops 3 gears; collecting all 3 triggers _do_transition().
# ──────────────────────────────────────────────────────────────────────────────

const ATTACK_INTERVAL := 2.5
const BOSS_MAX_HP     := 3
const BOSS_GEARS      := 3

@onready var boss          : Area2D = $PetalBoss
@onready var shield_pickup : Area2D = $ShieldPickup
@onready var attacks_node  : Node2D = $Attacks
@onready var boss_hp_label : Label  = $UI/BossHPLabel
@onready var hint_label    : Label  = $UI/HintLabel

var petal_attack_scene := preload("res://scenes/PetalAttack.tscn")

var boss_hp      := BOSS_MAX_HP
var attack_timer := -1.5   # grace period before first shot

var _flowers    := []
var _grass_tuft := []


# ── Configuration ─────────────────────────────────────────────────────────────

func _configure() -> void:
	gears_to_win     = BOSS_GEARS
	num_gears        = 0            # no gears at start; spawned after boss dies
	next_scene_path  = ""           # final level – no scene to load
	transition_title = "You beat Petal!\nAmazing work! :)"
	transition_color = Color(1.0, 0.85, 0.20, 1.0)


# ── Level setup ───────────────────────────────────────────────────────────────

func _level_setup() -> void:
	shield_pickup.body_entered.connect(_on_shield_touched)
	_update_boss_hp()
	hint_label.text = "Dodge attacks!\nFind the shield!"
	_setup_background()


func _spawn_collectibles() -> void:
	pass   # gears appear only after the boss is defeated


# ── Main loop ─────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _won:
		return
	if is_instance_valid(boss) and boss_hp > 0:
		attack_timer += delta
		if attack_timer >= ATTACK_INTERVAL:
			attack_timer = 0.0
			_spawn_attack()


# ── Spawning ──────────────────────────────────────────────────────────────────

func _spawn_attack() -> void:
	var atk: Area2D = petal_attack_scene.instantiate()
	atk.global_position = boss.global_position
	attacks_node.add_child(atk)
	atk.launch(player.global_position)
	atk.body_entered.connect(_on_petal_hit_player.bind(atk))
	atk.area_entered.connect(_on_petal_hit_boss.bind(atk))


func _spawn_boss_gears() -> void:
	var vp := get_viewport_rect().size
	for i in range(BOSS_GEARS):
		var ang := i * TAU / float(BOSS_GEARS)
		# Use base _spawn_gear helper – it wires up _on_gear_touched automatically
		var gear: Area2D = gear_scene.instantiate()
		gear.position = Vector2(
			vp.x * 0.50 + cos(ang) * 65.0,
			vp.y * 0.30 + sin(ang) * 55.0
		)
		gears_node.add_child(gear)
		gear.body_entered.connect(_on_gear_touched.bind(gear))


# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_petal_hit_player(body: Node2D, atk: Area2D) -> void:
	if body != player or not is_instance_valid(atk) or atk.reflected:
		return
	if player.has_shield:
		atk.reflect()
	else:
		player.position = _start_pos
		player.velocity  = Vector2.ZERO
		_flash_player_red()


func _on_petal_hit_boss(area: Area2D, atk: Area2D) -> void:
	if not is_instance_valid(boss) or area != boss:
		return
	if not is_instance_valid(atk) or not atk.reflected:
		return
	if boss_hp <= 0:
		return

	boss_hp -= 1
	boss.flash_hit()
	atk.queue_free()
	_update_boss_hp()

	if boss_hp <= 0:
		_boss_defeated()


func _on_shield_touched(body: Node2D) -> void:
	if body != player or player.has_shield:
		return
	player.has_shield = true
	shield_pickup.collect()
	player.modulate = Color(0.55, 0.80, 1.0)
	hint_label.text = "Shield acquired!\nRun INTO attacks to reflect them!"


# ── Game state ────────────────────────────────────────────────────────────────

func _boss_defeated() -> void:
	boss.explode()
	hint_label.text = "Boss defeated!\nCollect the 3 gears!"
	get_tree().create_timer(0.65).timeout.connect(_spawn_boss_gears)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _flash_player_red() -> void:
	var tween := create_tween()
	tween.tween_property(player, "modulate", Color(3.0, 0.5, 0.5), 0.07)
	var restore := Color(0.55, 0.80, 1.0) if player.has_shield else Color(1.0, 1.0, 1.0)
	tween.tween_property(player, "modulate", restore, 0.22)


func _update_boss_hp() -> void:
	boss_hp_label.text = "Boss HP: %d / %d" % [boss_hp, BOSS_MAX_HP]


func _setup_background() -> void:
	var vp := get_viewport_rect().size
	var flower_colors := [
		Color(1.0, 0.30, 0.55), Color(1.0, 0.70, 0.20),
		Color(0.80, 0.20, 1.0), Color(1.0, 1.0, 0.30),
		Color(1.0, 1.0, 1.0),   Color(0.60, 1.0, 0.40),
	]
	for _i in range(80):
		_flowers.append([
			Vector2(randf_range(10.0, vp.x - 10.0),
			        randf_range(vp.y * 0.45, vp.y - 10.0)),
			flower_colors[randi() % flower_colors.size()],
			randf_range(3.5, 7.5),
		])
	for _i in range(50):
		_grass_tuft.append(
			Vector2(randf_range(0.0, vp.x), randf_range(vp.y * 0.42, vp.y))
		)


# ── Background drawing ────────────────────────────────────────────────────────

func _draw() -> void:
	var vp := get_viewport_rect().size

	# Deep purple-pink sky
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.26, 0.08, 0.30, 1.0))

	# Glowing horizon band
	for i in range(8):
		var alpha := 0.10 * (1.0 - i / 7.0)
		draw_rect(Rect2(Vector2(0.0, vp.y * 0.35 + i * 16.0), Vector2(vp.x, 16.0)),
			Color(0.85, 0.20, 0.55, alpha))

	# Grass ground
	draw_rect(Rect2(Vector2(0.0, vp.y * 0.50), Vector2(vp.x, vp.y * 0.50)),
		Color(0.16, 0.40, 0.10, 1.0))

	# Grass tufts
	for gt in _grass_tuft:
		draw_line(gt, gt + Vector2(-4.0, -13.0), Color(0.22, 0.58, 0.14), 1.4)
		draw_line(gt, gt + Vector2( 0.0, -15.0), Color(0.28, 0.64, 0.17), 1.4)
		draw_line(gt, gt + Vector2( 4.0, -13.0), Color(0.22, 0.58, 0.14), 1.4)

	# Flowers
	for fl in _flowers:
		var fp : Vector2 = fl[0]
		var fc : Color   = fl[1]
		var sz : float   = fl[2]
		draw_line(fp, fp + Vector2(0.0, sz * 2.2), Color(0.20, 0.55, 0.12), 1.2)
		for k in range(5):
			var ang := k * TAU / 5.0
			draw_circle(fp + Vector2(cos(ang), sin(ang)) * sz * 0.9, sz * 0.55, fc)
		draw_circle(fp, sz * 0.50, Color(1.0, 0.95, 0.50, 1.0))
