class_name ArenaVisual
extends Node2D
## Side-view arena art with a separate lightweight animated foreground layer.

const ARENA_ART: Texture2D = preload("res://assets/backgrounds/neon_sakura_arena.png")

const WIDTH: float = 1920.0
const HEIGHT: float = 1080.0
const FLOOR_Y: float = 850.0

var _time: float = 0.0
var _camera_offset: Vector2 = Vector2.ZERO


func set_camera_offset(value: Vector2) -> void:
	_camera_offset = value
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var shift := -_camera_offset.x * 0.08
	draw_texture_rect(ARENA_ART, Rect2(-24.0 + shift, -13.0, WIDTH + 48.0, HEIGHT + 26.0), false)
	# The visual ground line matches the physics floor at y = 850.
	draw_line(Vector2(0.0, FLOOR_Y), Vector2(WIDTH, FLOOR_Y), Color(0.91, 0.52, 0.98, 0.24), 3.0, true)
	for i in 18:
		var phase := float(i) * 1.43
		var x := fposmod(float(i * 157) + _time * (24.0 + float(i % 4) * 10.0), WIDTH)
		var y := 260.0 + fposmod(float(i * 83) + sin(_time * 0.55 + phase) * 31.0, 570.0)
		var petal := Color("#ffa1dc") if i % 3 != 0 else Color("#bd8bff")
		petal.a = 0.26 + 0.12 * sin(_time * 1.8 + phase)
		draw_circle(Vector2(x, y), 2.0 + float(i % 3), petal)


func _draw_sky() -> void:
	var top := Color("#08091c")
	var horizon := Color("#281336")
	for i in 22:
		var ratio: float = float(i) / 21.0
		draw_rect(Rect2(0.0, float(i) * 39.0, WIDTH, 40.0), top.lerp(horizon, pow(ratio, 1.7)))
	# Broad, dim columns lead the eye into the fight space.
	for i in 9:
		var x: float = 75.0 + float(i) * 235.0
		draw_line(Vector2(x, 0.0), Vector2(x - 45.0, FLOOR_Y), Color(0.35, 0.09, 0.44, 0.06), 90.0, true)
	for i in 36:
		var sx: float = float((i * 337 + 97) % 1900)
		var sy: float = float((i * 191 + 43) % 510) + 44.0
		var flicker: float = 0.45 + 0.23 * sin(_time * (0.6 + float(i % 4) * 0.17) + float(i))
		draw_circle(Vector2(sx, sy), 1.5 + float(i % 3), Color(0.67, 0.67, 1.0, flicker))


func _draw_moon_and_spires() -> void:
	var moon := Vector2(961.0, 322.0)
	draw_circle(moon, 140.0, Color(0.42, 0.22, 0.67, 0.06))
	draw_circle(moon, 103.0, Color(0.53, 0.29, 0.72, 0.10))
	draw_circle(moon, 71.0, Color("#9d77ad"))
	draw_circle(moon + Vector2(-12.0, -13.0), 64.0, Color("#d9b9db"))
	draw_circle(moon + Vector2(17.0, -18.0), 64.0, Color("#281939"))
	draw_arc(moon, 107.0, 0.0, TAU, 48, Color(0.73, 0.38, 1.0, 0.30), 2.0, true)
	for side in [-1.0, 1.0]:
		for i in 3:
			var bx: float = 960.0 + side * (230.0 + float(i) * 190.0)
			var roof_y: float = 570.0 - float(i % 2) * 90.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(bx - 63.0, FLOOR_Y), Vector2(bx - 45.0, roof_y),
				Vector2(bx, roof_y - 145.0), Vector2(bx + 45.0, roof_y),
				Vector2(bx + 63.0, FLOOR_Y)
			]), Color("#190f2d"))
			draw_line(Vector2(bx, roof_y - 145.0), Vector2(bx, roof_y - 182.0), Color("#643977"), 3.0, true)


func _draw_city() -> void:
	for i in 24:
		var x: float = float(i) * 91.0 - 64.0
		var building_height: float = 135.0 + float((i * 157) % 202)
		var y: float = FLOOR_Y - building_height
		draw_rect(Rect2(x, y, 76.0, building_height), Color("#10132b"))
		draw_line(Vector2(x, y), Vector2(x + 76.0, y), Color(0.48, 0.22, 0.65, 0.35), 3.0, true)
		for row in 3:
			for col in 2:
				if (i + row * 2 + col) % 4 != 0:
					var window_y: float = y + 27.0 + float(row) * 36.0
					draw_rect(Rect2(x + 15.0 + float(col) * 34.0, window_y, 10.0, 13.0), Color(0.19, 0.57, 0.82, 0.15 + 0.07 * sin(_time + float(i))))
	# Magenta and cyan cables indicate depth without cluttering the collision plane.
	for i in 4:
		var cable_y: float = 594.0 + float(i) * 48.0
		draw_line(Vector2(0.0, cable_y), Vector2(WIDTH, cable_y + 14.0), Color(0.61, 0.19, 0.69, 0.13), 2.0, true)


func _draw_arena_walls() -> void:
	var trim := Color("#672c85")
	var wall := Color("#241631")
	# A shallow shrine-like gate frames the center without hiding either fighter.
	draw_colored_polygon(PackedVector2Array([
		Vector2(504.0, 532.0), Vector2(594.0, 488.0),
		Vector2(960.0, 519.0), Vector2(1326.0, 488.0),
		Vector2(1416.0, 532.0), Vector2(960.0, 551.0)
	]), wall)
	draw_polyline(PackedVector2Array([
		Vector2(504.0, 532.0), Vector2(594.0, 488.0),
		Vector2(960.0, 519.0), Vector2(1326.0, 488.0),
		Vector2(1416.0, 532.0)
	]), trim, 4.0, true)
	for x in [588.0, 1332.0]:
		draw_rect(Rect2(x - 14.0, 523.0, 28.0, 308.0), Color("#1e142d"))
		draw_rect(Rect2(x - 5.0, 523.0, 4.0, 308.0), Color(0.56, 0.31, 0.70, 0.39))
	for side in [-1.0, 1.0]:
		for i in 3:
			var x: float = 960.0 + side * (257.0 + 185.0 * float(i))
			_draw_lantern(Vector2(x, 603.0 + float(i % 2) * 27.0))
	# Railing and repeated arch silhouettes sit behind the fighters.
	draw_line(Vector2(0.0, 761.0), Vector2(WIDTH, 761.0), Color("#5b297a"), 7.0, true)
	draw_line(Vector2(0.0, 775.0), Vector2(WIDTH, 775.0), Color("#2b1c40"), 17.0, true)
	for i in 13:
		var x: float = 43.0 + 153.0 * float(i)
		draw_line(Vector2(x, 762.0), Vector2(x, 830.0), Color("#3b254e"), 10.0, true)
		draw_arc(Vector2(x + 76.5, 797.0), 63.0, PI, TAU, 20, Color("#4a2b63"), 5.0, true)


func _draw_lantern(center: Vector2) -> void:
	var pulse: float = 0.58 + 0.16 * sin(_time * 1.7 + center.x * 0.01)
	draw_line(center + Vector2(0.0, -40.0), center + Vector2(0.0, -19.0), Color("#75465e"), 3.0, true)
	draw_circle(center, 29.0, Color(1.0, 0.31, 0.36, 0.06 + 0.05 * pulse))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-14.0, -17.0), center + Vector2(14.0, -17.0),
		center + Vector2(17.0, 11.0), center + Vector2(0.0, 19.0),
		center + Vector2(-17.0, 11.0)
	]), Color(0.94, 0.22, 0.37, pulse))
	draw_line(center + Vector2(-14.0, -17.0), center + Vector2(14.0, -17.0), Color("#ffc0ac"), 3.0, true)
	draw_line(center + Vector2(0.0, -15.0), center + Vector2(0.0, 17.0), Color(1.0, 0.77, 0.49, 0.44), 2.0, true)


func _draw_ground() -> void:
	draw_rect(Rect2(0.0, FLOOR_Y, WIDTH, HEIGHT - FLOOR_Y), Color("#17182b"))
	draw_rect(Rect2(0.0, FLOOR_Y - 11.0, WIDTH, 11.0), Color("#26213e"))
	draw_line(Vector2(0.0, FLOOR_Y), Vector2(WIDTH, FLOOR_Y), Color("#ba58da"), 5.0, true)
	draw_line(Vector2(0.0, FLOOR_Y + 7.0), Vector2(WIDTH, FLOOR_Y + 7.0), Color(0.59, 0.30, 0.83, 0.19), 11.0, true)
	# Wide floor tiles make the grounded collision line obvious.
	for i in 8:
		var y: float = FLOOR_Y + 15.0 + float(i * i) * 4.1
		draw_line(Vector2(0.0, y), Vector2(WIDTH, y), Color(0.33, 0.39, 0.62, 0.22), 2.0, true)
	for i in 16:
		var x: float = 85.0 + 125.0 * float(i)
		draw_line(Vector2(x, FLOOR_Y + 12.0), Vector2(960.0 + (x - 960.0) * 1.35, HEIGHT), Color(0.43, 0.32, 0.69, 0.21), 2.0, true)
	for i in 8:
		var x: float = 88.0 + float(i) * 249.0
		draw_line(Vector2(x, FLOOR_Y + 15.0), Vector2(x + 84.0, FLOOR_Y + 15.0), Color(0.37, 0.83, 0.95, 0.17), 3.0, true)
