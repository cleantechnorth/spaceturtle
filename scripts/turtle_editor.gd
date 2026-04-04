extends Node2D
# ──────────────────────────────────────────────────────────────────────────────
# Turtle Icon Editor
#
# Lets the player choose a colour tint for their turtle before playing.
# The actual turtle.svg is shown as a Sprite2D so the tint preview is accurate.
# Colour swatches are drawn via _draw(); clicks update TurtleSettings and the
# sprite's modulate property.
# ──────────────────────────────────────────────────────────────────────────────

const SWATCHES : Array[Dictionary] = [
	{ "label": "Classic",   "color": Color(1.00, 1.00, 1.00) },
	{ "label": "Emerald",   "color": Color(0.40, 1.00, 0.55) },
	{ "label": "Ocean",     "color": Color(0.45, 0.75, 1.00) },
	{ "label": "Fire",      "color": Color(1.00, 0.48, 0.30) },
	{ "label": "Violet",    "color": Color(0.80, 0.42, 1.00) },
	{ "label": "Gold",      "color": Color(1.00, 0.88, 0.20) },
	{ "label": "Hot Pink",  "color": Color(1.00, 0.42, 0.78) },
	{ "label": "Cyber",     "color": Color(0.28, 0.98, 0.98) },
	{ "label": "Lava",      "color": Color(1.00, 0.32, 0.10) },
]

const SWATCH_R   := 34.0
const SWATCH_GAP := 18.0
const SWATCH_Y   := 475.0

# ── Starfield ─────────────────────────────────────────────────────────────────
var _star_positions := PackedVector2Array()
var _star_sizes     := PackedFloat32Array()
var _star_colors    := []
var _nebula         := []
var _time           := 0.0

# ── UI state ──────────────────────────────────────────────────────────────────
var _swatch_centers : Array = []   # Array[Vector2]
var _hovered_swatch := -1
var _back_hover     := false
var _back_rect      := Rect2()

# ── Turtle sprite (actual SVG, tinted) ────────────────────────────────────────
var _turtle_sprite : Sprite2D


func _ready() -> void:
	var vp := get_viewport_rect().size

	# Starfield
	_nebula = [
		[Vector2(145,  128), 210.0, Color(0.28, 0.07, 0.52, 0.12)],
		[Vector2(875,   98), 185.0, Color(0.08, 0.16, 0.62, 0.10)],
		[Vector2(512,  520), 165.0, Color(0.38, 0.09, 0.52, 0.09)],
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var palettes := [
		Color(1.0, 1.0, 1.0, 0.90), Color(0.85, 0.92, 1.0, 0.85),
		Color(0.75, 0.88, 1.0, 0.80), Color(1.0, 0.95, 0.80, 0.80),
	]
	for i in range(130):
		_star_positions.append(Vector2(rng.randf_range(0.0, vp.x), rng.randf_range(0.0, vp.y)))
		_star_sizes.append(rng.randf_range(0.5, 2.5))
		_star_colors.append(palettes[i % palettes.size()])

	# Pre-compute swatch positions (centred horizontally)
	var total_w := SWATCHES.size() * (SWATCH_R * 2.0) + (SWATCHES.size() - 1) * SWATCH_GAP
	var start_x := (vp.x - total_w) / 2.0 + SWATCH_R
	for i in range(SWATCHES.size()):
		_swatch_centers.append(Vector2(start_x + i * (SWATCH_R * 2.0 + SWATCH_GAP), SWATCH_Y))

	# Turtle sprite – real SVG, centred in the preview area
	_turtle_sprite = Sprite2D.new()
	_turtle_sprite.texture  = load("res://assets/turtle.svg")
	_turtle_sprite.position = Vector2(vp.x * 0.5, 280.0)
	_turtle_sprite.scale    = Vector2(3.2, 3.2)
	_turtle_sprite.modulate = TurtleSettings.turtle_modulate
	add_child(_turtle_sprite)

	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mp: Vector2 = (event as InputEventMouseMotion).position
		var prev_sw     := _hovered_swatch
		var prev_back   := _back_hover
		_hovered_swatch = -1
		_back_hover     = false

		for i in range(_swatch_centers.size()):
			if (_swatch_centers[i] as Vector2).distance_to(mp) <= SWATCH_R + 5.0:
				_hovered_swatch = i
				break
		if _back_rect.has_point(mp):
			_back_hover = true

		if _hovered_swatch != prev_sw or _back_hover != prev_back:
			queue_redraw()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mp: Vector2 = (event as InputEventMouseButton).position
			# Swatch click
			for i in range(_swatch_centers.size()):
				if (_swatch_centers[i] as Vector2).distance_to(mp) <= SWATCH_R + 5.0:
					TurtleSettings.turtle_modulate = SWATCHES[i].color
					_turtle_sprite.modulate        = SWATCHES[i].color
					queue_redraw()
					return
			# Back button
			if _back_rect.has_point(mp):
				get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")


# ── Master draw ───────────────────────────────────────────────────────────────

func _draw() -> void:
	var vp := get_viewport_rect().size
	_draw_background(vp)
	_draw_title(vp)
	_draw_preview_frame(vp)
	_draw_swatches()
	_draw_back_button(vp)


# ── Background ────────────────────────────────────────────────────────────────

func _draw_background(vp: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.04, 0.02, 0.12, 1.0))
	for blob in _nebula:
		draw_circle(blob[0], blob[1], blob[2])
	for i in _star_positions.size():
		var sz : float = _star_sizes[i]
		var tw : float = 0.80 + 0.20 * sin(_time * 1.8 + i * 0.61)
		draw_circle(_star_positions[i], sz * tw, _star_colors[i])


# ── Title ─────────────────────────────────────────────────────────────────────

func _draw_title(vp: Vector2) -> void:
	var font  := ThemeDB.fallback_font
	var title := "Turtle Icon Editor"
	var fs    := 54

	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var tx := (vp.x - tw) * 0.5

	# Outline
	for dx in [-2, 0, 2]:
		for dy in [-2, 0, 2]:
			if dx != 0 or dy != 0:
				draw_string(font, Vector2(tx + dx, 70.0 + dy), title,
					HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.05, 0.20, 0.08, 0.82))
	draw_string(font, Vector2(tx, 70.0), title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.35, 0.92, 0.45, 1.0))

	# Subtitle
	var sub := "Choose your turtle's colour!"
	var sfs := 23
	var sw  := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs).x
	draw_string(font, Vector2((vp.x - sw) * 0.5, 106.0),
		sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs, Color(0.72, 0.87, 1.00, 0.92))


# ── Soft frame behind the turtle sprite ───────────────────────────────────────

func _draw_preview_frame(vp: Vector2) -> void:
	var center := Vector2(vp.x * 0.5, 280.0)
	# Soft dark oval so the turtle stands out against the stars
	_draw_ellipse(center, 190.0, 90.0, Color(0.0, 0.0, 0.08, 0.55))
	# Subtle border
	draw_arc(center, 192.0, 0.0, TAU, 64, Color(0.35, 0.92, 0.45, 0.18), 3.0)

	# Selected colour label below sprite
	var font     := ThemeDB.fallback_font
	var col_name := _color_label(TurtleSettings.turtle_modulate)
	var cw       := font.get_string_size(col_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	draw_string(font, Vector2(center.x - cw * 0.5, 355.0),
		col_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.90, 0.90, 0.90, 0.95))

	# Colour dot next to the label
	draw_circle(Vector2(center.x - cw * 0.5 - 22.0, 345.0),
		10.0, TurtleSettings.turtle_modulate)
	draw_arc(Vector2(center.x - cw * 0.5 - 22.0, 345.0),
		10.0, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.55), 2.0)


func _color_label(c: Color) -> String:
	for sw in SWATCHES:
		if (sw.color as Color).is_equal_approx(c):
			return sw.label
	return "Custom"


# ── Colour swatches ───────────────────────────────────────────────────────────

func _draw_swatches() -> void:
	var font := ThemeDB.fallback_font

	for i in range(SWATCHES.size()):
		var center    := _swatch_centers[i] as Vector2
		var sw        := SWATCHES[i]
		var selected  := TurtleSettings.turtle_modulate.is_equal_approx(sw.color as Color)
		var hovered   := _hovered_swatch == i

		# Drop shadow
		draw_circle(center + Vector2(2.5, 2.5), SWATCH_R, Color(0.0, 0.0, 0.0, 0.35))

		# Main circle (slightly larger when hovered)
		var r := SWATCH_R + (5.0 if hovered else 0.0)
		draw_circle(center, r, sw.color as Color)

		# Highlight sheen
		_draw_ellipse(center + Vector2(-r * 0.22, -r * 0.28), r * 0.45, r * 0.28,
			Color(1.0, 1.0, 1.0, 0.22))

		# Border
		var border_col := Color(1.0, 1.0, 1.0, 0.90) if selected else Color(0.55, 0.55, 0.65, 0.55)
		var border_w   := 4.5 if selected else 2.0
		draw_arc(center, r, 0.0, TAU, 32, border_col, border_w)

		# Tick mark for selected swatch
		if selected:
			# Dark shadow tick
			draw_line(center + Vector2(-11, 1), center + Vector2(-3, 10),
				Color(0.0, 0.0, 0.0, 0.55), 3.5)
			draw_line(center + Vector2(-3, 10), center + Vector2(13, -7),
				Color(0.0, 0.0, 0.0, 0.55), 3.5)
			# White tick
			draw_line(center + Vector2(-11, 0), center + Vector2(-3, 9),
				Color(1.0, 1.0, 1.0, 0.92), 2.5)
			draw_line(center + Vector2(-3, 9), center + Vector2(13, -8),
				Color(1.0, 1.0, 1.0, 0.92), 2.5)

		# Name label
		var lbl := sw.label as String
		var lw  := font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, Vector2(center.x - lw * 0.5, center.y + SWATCH_R + 20.0),
			lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.82, 0.88, 0.95, 0.92))


# ── Back button ───────────────────────────────────────────────────────────────

func _draw_back_button(vp: Vector2) -> void:
	var cx := 88.0
	var cy := vp.y - 42.0
	var w  := 128.0
	var h  := 46.0
	_back_rect = Rect2(cx - w * 0.5, cy - h * 0.5, w, h)

	var col := Color(0.26, 0.14, 0.44) if not _back_hover else Color(0.40, 0.22, 0.64)

	# Arrow-tab shape
	var pts := PackedVector2Array([
		Vector2(cx - w * 0.5 + 14.0, cy - h * 0.5),
		Vector2(cx + w * 0.5,        cy - h * 0.5),
		Vector2(cx + w * 0.5,        cy + h * 0.5),
		Vector2(cx - w * 0.5 + 14.0, cy + h * 0.5),
		Vector2(cx - w * 0.5,        cy),
	])
	draw_colored_polygon(pts, col)
	var bpts := pts.duplicate()
	bpts.append(pts[0])
	draw_polyline(bpts, Color(0.68, 0.46, 0.92, 0.88), 2.5)

	var font := ThemeDB.fallback_font
	var lbl  := "< Back"
	var lw   := font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x
	draw_string(font, Vector2(cx - lw * 0.5, cy + 9.0),
		lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(0.92, 0.82, 1.00, 1.0))


# ── Helper ────────────────────────────────────────────────────────────────────

func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color,
		angle: float = 0.0, segs: int = 28) -> void:
	var pts := PackedVector2Array()
	for i in range(segs):
		var a  := TAU * i / segs
		var px := cos(a) * rx
		var py := sin(a) * ry
		pts.append(center + Vector2(
			px * cos(angle) - py * sin(angle),
			px * sin(angle) + py * cos(angle)
		))
	draw_colored_polygon(pts, color)
