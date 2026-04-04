extends Node2D
# ──────────────────────────────────────────────────────────────────────────────
# Title Screen – "DASH TURTLE WORLD"
#
# Layout (1024 × 600):
#   Top area   – "DASH" (left, gold) + "TURTLE" (right, green) + "WORLD" (sub)
#   Mid-right  – decorative blue-green planet
#   Bottom-left – Turtle Icon Editor button (asteroid shape)
#   Bottom-mid  – PLAY button (rocky planet with play triangle)
#
# All visuals drawn via _draw(); mouse interaction via _input().
# ──────────────────────────────────────────────────────────────────────────────

# ── Starfield ─────────────────────────────────────────────────────────────────
var _star_positions := PackedVector2Array()
var _star_sizes     := PackedFloat32Array()
var _star_colors    := []
var _nebula         := []

# ── Button state ──────────────────────────────────────────────────────────────
var _play_rect   := Rect2()
var _editor_rect := Rect2()
var _play_hover   := false
var _editor_hover := false

# ── Animation ─────────────────────────────────────────────────────────────────
var _time := 0.0


func _ready() -> void:
	var vp := get_viewport_rect().size

	# Nebula blobs
	_nebula = [
		[Vector2(140,  125), 220.0, Color(0.28, 0.07, 0.52, 0.12)],
		[Vector2(880,   95), 195.0, Color(0.08, 0.16, 0.62, 0.10)],
		[Vector2(730,  490), 175.0, Color(0.38, 0.09, 0.52, 0.09)],
		[Vector2(195,  480), 155.0, Color(0.18, 0.05, 0.58, 0.08)],
		[Vector2(512,  300), 270.0, Color(0.08, 0.14, 0.48, 0.06)],
	]

	# Stars – seed with fixed value for consistent look
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var palettes := [
		Color(1.00, 1.00, 1.00, 0.90),
		Color(0.85, 0.92, 1.00, 0.85),
		Color(0.75, 0.88, 1.00, 0.80),
		Color(1.00, 0.95, 0.80, 0.80),
		Color(1.00, 0.80, 0.70, 0.70),
	]
	for i in range(170):
		_star_positions.append(Vector2(rng.randf_range(0.0, vp.x), rng.randf_range(0.0, vp.y)))
		_star_sizes.append(rng.randf_range(0.5, 2.6))
		_star_colors.append(palettes[i % palettes.size()])

	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mp: Vector2 = (event as InputEventMouseMotion).position
		var prev_p := _play_hover
		var prev_e := _editor_hover
		_play_hover   = _play_rect.has_point(mp)
		_editor_hover = _editor_rect.has_point(mp)
		if _play_hover != prev_p or _editor_hover != prev_e:
			queue_redraw()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mp: Vector2 = (event as InputEventMouseButton).position
			if _play_rect.has_point(mp):
				get_tree().change_scene_to_file("res://scenes/Main.tscn")
			elif _editor_rect.has_point(mp):
				get_tree().change_scene_to_file("res://scenes/TurtleEditor.tscn")


# ── Master draw ───────────────────────────────────────────────────────────────

func _draw() -> void:
	var vp := get_viewport_rect().size
	_draw_background(vp)
	_draw_title(vp)
	_draw_world_planet(vp)
	_draw_editor_button(vp)
	_draw_play_button(vp)


# ── Background ────────────────────────────────────────────────────────────────

func _draw_background(vp: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.04, 0.02, 0.12, 1.0))
	for blob in _nebula:
		draw_circle(blob[0], blob[1], blob[2])
	for i in _star_positions.size():
		var sz  : float = _star_sizes[i]
		var tw  : float = 0.80 + 0.20 * sin(_time * 1.8 + i * 0.61)
		draw_circle(_star_positions[i], sz * tw, _star_colors[i])
		if sz > 2.0:
			var p := _star_positions[i]
			var c := Color(_star_colors[i].r, _star_colors[i].g, _star_colors[i].b, 0.25 * tw)
			draw_line(p + Vector2(-sz * 3.0, 0.0), p + Vector2(sz * 3.0, 0.0), c, 0.5)
			draw_line(p + Vector2(0.0, -sz * 3.0), p + Vector2(0.0, sz * 3.0), c, 0.5)


# ── Title text ────────────────────────────────────────────────────────────────

func _draw_title(_vp: Vector2) -> void:
	var font := ThemeDB.fallback_font

	# ── "DASH" – top-left, gold ────────────────────────────────────────────────
	var dash_str := "DASH"
	var dash_fs  := 84
	var dash_x   := 62.0
	var dash_y   := 172.0   # baseline

	# Speed lines (the = marks in the drawing)
	for k in range(3):
		var ly := dash_y - 72.0 + k * 24.0
		draw_line(Vector2(18.0, ly), Vector2(58.0, ly),
			Color(0.95, 0.82, 0.18, 0.75 - k * 0.18), 3.5 - k * 0.6)

	# Dark outline
	for dx in [-3, 0, 3]:
		for dy in [-3, 0, 3]:
			if dx != 0 or dy != 0:
				draw_string(font, Vector2(dash_x + dx, dash_y + dy), dash_str,
					HORIZONTAL_ALIGNMENT_LEFT, -1, dash_fs, Color(0.08, 0.04, 0.25, 0.80))
	draw_string(font, Vector2(dash_x, dash_y), dash_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, dash_fs, Color(0.96, 0.84, 0.18, 1.0))

	# ── "TURTLE" – top-right, green ───────────────────────────────────────────
	var turtle_str := "TURTLE"
	var turtle_fs  := 104
	var turtle_w   := font.get_string_size(turtle_str, HORIZONTAL_ALIGNMENT_LEFT, -1, turtle_fs).x
	var turtle_x   := 1024.0 - 52.0 - turtle_w
	var turtle_y   := 170.0

	for dx in [-3, 0, 3]:
		for dy in [-3, 0, 3]:
			if dx != 0 or dy != 0:
				draw_string(font, Vector2(turtle_x + dx, turtle_y + dy), turtle_str,
					HORIZONTAL_ALIGNMENT_LEFT, -1, turtle_fs, Color(0.05, 0.22, 0.08, 0.80))
	draw_string(font, Vector2(turtle_x, turtle_y), turtle_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, turtle_fs, Color(0.35, 0.92, 0.45, 1.0))

	# ── "WORLD" – subtitle below TURTLE, blue-white ───────────────────────────
	var world_str := "WORLD"
	var world_fs  := 58
	var world_w   := font.get_string_size(world_str, HORIZONTAL_ALIGNMENT_LEFT, -1, world_fs).x
	var world_x   := 1024.0 - 52.0 - world_w
	var world_y   := 242.0

	for dx in [-2, 0, 2]:
		for dy in [-2, 0, 2]:
			if dx != 0 or dy != 0:
				draw_string(font, Vector2(world_x + dx, world_y + dy), world_str,
					HORIZONTAL_ALIGNMENT_LEFT, -1, world_fs, Color(0.05, 0.10, 0.35, 0.75))
	draw_string(font, Vector2(world_x, world_y), world_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, world_fs, Color(0.48, 0.78, 1.00, 1.0))


# ── Decorative planet ("WORLD" planet, mid-right) ─────────────────────────────

func _draw_world_planet(_vp: Vector2) -> void:
	var center := Vector2(838.0, 390.0)
	var r      := 52.0
	var pulse  := 1.0 + 0.03 * sin(_time * 0.9)

	# Planet body – blue ocean base
	draw_circle(center, r * pulse, Color(0.12, 0.42, 0.82))
	# Ocean shimmer
	draw_circle(center, r * pulse, Color(0.05, 0.18, 0.60, 0.45))
	# Continents
	_draw_ellipse(center + Vector2(-16.0,  -9.0), 20.0, 13.0, Color(0.28, 0.68, 0.24, 0.88))
	_draw_ellipse(center + Vector2( 14.0,  10.0), 14.0, 10.0, Color(0.28, 0.68, 0.24, 0.88))
	_draw_ellipse(center + Vector2( -4.0,  22.0), 10.0,  7.0, Color(0.22, 0.60, 0.18, 0.88))
	_draw_ellipse(center + Vector2( 26.0, -22.0),  9.0,  6.0, Color(0.28, 0.68, 0.24, 0.80))
	# Atmosphere ring
	draw_arc(center, r * pulse + 5.0, 0.0, TAU, 48, Color(0.45, 0.75, 1.00, 0.22), 5.5)
	# Cloud wisps
	_draw_ellipse(center + Vector2(-10.0, -30.0), 16.0, 4.0, Color(1.0, 1.0, 1.0, 0.18))
	_draw_ellipse(center + Vector2( 18.0,  28.0), 12.0, 3.5, Color(1.0, 1.0, 1.0, 0.18))


# ── Turtle Icon Editor button (asteroid shape, bottom-left) ───────────────────

func _draw_editor_button(_vp: Vector2) -> void:
	var center := Vector2(222.0, 452.0)
	var rx     := 96.0
	var ry     := 86.0
	_editor_rect = Rect2(center - Vector2(rx, ry), Vector2(rx * 2.0, ry * 2.0))

	var hover_glow := 0.0
	if _editor_hover:
		hover_glow = 8.0 + 4.0 * sin(_time * 3.5)
		draw_circle(center, rx + hover_glow, Color(0.90, 0.62, 0.18, 0.22))

	# Asteroid polygon (irregular rock shape)
	var base_col := Color(0.30, 0.18, 0.10) if not _editor_hover else Color(0.44, 0.27, 0.14)
	var segs  := 10
	var radii := [rx, rx*0.86, ry*1.02, rx*0.91, rx, rx*0.88, ry, rx*0.93, rx*0.96, rx*0.84]
	var ry_s  := [ry*0.90, ry, ry*0.86, ry*1.02, ry*0.92, ry, ry*0.88, ry*0.96, ry*0.84, ry]
	var pts   := PackedVector2Array()
	for i in range(segs):
		var a := TAU * i / segs - PI / 2.0
		pts.append(center + Vector2(cos(a) * radii[i], sin(a) * ry_s[i]))
	draw_colored_polygon(pts, base_col)
	var bpts := pts.duplicate()
	bpts.append(pts[0])
	draw_polyline(bpts, Color(0.75, 0.50, 0.22, 0.88), 3.0)

	# Surface craters / texture
	draw_circle(center + Vector2(-40.0, -28.0), 12.0, Color(0.22, 0.12, 0.06, 0.70))
	draw_circle(center + Vector2( 38.0,  32.0),  8.0, Color(0.22, 0.12, 0.06, 0.70))
	draw_circle(center + Vector2(-10.0,  40.0),  6.0, Color(0.22, 0.12, 0.06, 0.70))

	# Mini turtle drawn on the rock
	_draw_mini_turtle(center + Vector2(-8.0, -12.0), 0.58)

	# Label
	var font := ThemeDB.fallback_font
	var lbl  := "turtle icon editor"
	var lw   := font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(font, Vector2(center.x - lw * 0.5, center.y + ry + 22.0),
		lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.96, 0.80, 0.28, 1.0))


# ── PLAY button (rocky planet with ▶, bottom-centre) ─────────────────────────

func _draw_play_button(_vp: Vector2) -> void:
	var center := Vector2(540.0, 452.0)
	var r      := 86.0
	_play_rect = Rect2(center - Vector2(r, r), Vector2(r * 2.0, r * 2.0))

	# Outer glow on hover / pulse
	if _play_hover:
		var glow := r + 14.0 + 5.0 * sin(_time * 3.5)
		draw_circle(center, glow, Color(0.30, 0.62, 1.00, 0.28))
	else:
		var pulse := r + 6.0 + 3.0 * sin(_time * 1.4)
		draw_circle(center, pulse, Color(0.20, 0.40, 0.80, 0.12))

	# Rocky planet base
	var base_col := Color(0.14, 0.32, 0.84) if not _play_hover else Color(0.22, 0.48, 1.0)
	draw_circle(center, r, base_col)
	# Ocean depth sheen
	draw_circle(center, r, Color(0.04, 0.14, 0.52, 0.50))
	# Continents
	_draw_ellipse(center + Vector2(-26.0, -16.0), 22.0, 15.0, Color(0.26, 0.66, 0.26, 0.88))
	_draw_ellipse(center + Vector2( 22.0,  20.0), 17.0, 12.0, Color(0.26, 0.66, 0.26, 0.88))
	_draw_ellipse(center + Vector2( -6.0,  32.0), 13.0,  8.0, Color(0.20, 0.58, 0.20, 0.88))
	_draw_ellipse(center + Vector2( 32.0, -30.0), 10.0,  7.0, Color(0.26, 0.66, 0.26, 0.80))
	# Atmosphere rim
	draw_arc(center, r, 0.0, TAU, 64, Color(0.52, 0.82, 1.00, 0.28), 6.0)
	# Ring
	var ra := deg_to_rad(-38.0)
	var rb := deg_to_rad( 38.0)
	draw_arc(center, r + 20.0, ra, rb, 22, Color(0.85, 0.80, 0.48, 0.72), 4.0)
	draw_arc(center, r + 20.0, ra + PI, rb + PI, 22, Color(0.85, 0.80, 0.48, 0.72), 4.0)

	# Play triangle (white, bold)
	var ts  := 30.0
	var tp  := center + Vector2(6.0, 0.0)
	var tri := PackedVector2Array([
		tp + Vector2(-ts * 0.65, -ts),
		tp + Vector2(-ts * 0.65,  ts),
		tp + Vector2( ts,          0.0),
	])
	draw_colored_polygon(tri, Color(1.0, 1.0, 1.0, 0.96))
	# Triangle outline
	var to_pts := tri.duplicate()
	to_pts.append(tri[0])
	draw_polyline(to_pts, Color(0.70, 0.88, 1.00, 0.55), 2.0)

	# "PLAY" label below button
	var font := ThemeDB.fallback_font
	var lbl  := "PLAY"
	var lw   := font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_string(font, Vector2(center.x - lw * 0.5, center.y + r + 28.0),
		lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.70, 0.90, 1.00, 1.0))


# ── Helpers ───────────────────────────────────────────────────────────────────

## Draw a solid filled ellipse (optionally rotated by `angle` radians).
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


## Draw a simplified turtle icon on the editor button.
func _draw_mini_turtle(pos: Vector2, s: float) -> void:
	# Back flippers
	_draw_ellipse(pos + Vector2(-30.0 * s, -18.0 * s), 14.0 * s, 5.5 * s,
		Color(0.42, 0.50, 0.50), -0.55)
	_draw_ellipse(pos + Vector2(-30.0 * s,  18.0 * s), 14.0 * s, 5.5 * s,
		Color(0.42, 0.50, 0.50),  0.55)
	# Shell
	_draw_ellipse(pos, 30.0 * s, 21.0 * s, Color(0.55, 0.36, 0.17))
	# Gear window
	_draw_ellipse(pos + Vector2(-10.0 * s, 0.0), 9.0 * s, 13.0 * s, Color(0.08, 0.05, 0.02))
	draw_arc(pos + Vector2(-10.0 * s, 1.5 * s), 8.0 * s, 0.0, TAU, 16,
		Color(0.78, 0.62, 0.18), 4.5 * s)
	# Front flippers
	_draw_ellipse(pos + Vector2(22.0 * s, -18.0 * s), 12.0 * s, 4.5 * s,
		Color(0.42, 0.50, 0.50), -0.45)
	_draw_ellipse(pos + Vector2(22.0 * s,  18.0 * s), 12.0 * s, 4.5 * s,
		Color(0.42, 0.50, 0.50),  0.45)
	# Head
	_draw_ellipse(pos + Vector2(38.0 * s, 0.0), 12.0 * s, 10.0 * s, Color(0.38, 0.46, 0.46))
	# Monocle
	draw_arc(pos + Vector2(43.0 * s, -3.0 * s), 6.0 * s, 0.0, TAU, 16,
		Color(0.78, 0.62, 0.18), 3.0 * s)
	draw_circle(pos + Vector2(43.0 * s, -3.0 * s), 4.0 * s, Color(0.04, 0.12, 0.28))
	draw_circle(pos + Vector2(41.0 * s, -5.0 * s), 1.5 * s, Color(1.0, 1.0, 1.0, 0.55))
