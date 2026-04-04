extends Node
# ──────────────────────────────────────────────────────────────────────────────
# TurtleSettings – global autoload singleton
#
# Stores player preferences that must survive scene changes, e.g. the colour
# tint applied to the turtle sprite.  Access from any script as:
#   TurtleSettings.turtle_modulate
# ──────────────────────────────────────────────────────────────────────────────

## The modulate colour applied to the Player's Sprite2D.
## Color(1,1,1,1) = default steampunk colours; any other value tints the turtle.
var turtle_modulate := Color(1.0, 1.0, 1.0, 1.0)
